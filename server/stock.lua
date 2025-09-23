local enabled = Config.Limits and Config.Limits.Enabled == true
if not enabled then return end

if Config.Limits.AutoMigrate then
    local createSql = [[
        CREATE TABLE IF NOT EXISTS peleg_vendor_limits (
            id INT AUTO_INCREMENT PRIMARY KEY,
            scope VARCHAR(16) NOT NULL,
            identifier VARCHAR(64) DEFAULT NULL,
            item VARCHAR(64) NOT NULL,
            quantity INT NOT NULL DEFAULT 0,
            day DATE NOT NULL,
            UNIQUE KEY uniq_player (scope, identifier, item, day),
            UNIQUE KEY uniq_global (scope, item, day),
            KEY idx_scope_day_item (scope, day, item),
            KEY idx_player_day_item (identifier, day, item)
        )
    ]]
    pcall(function() exports.oxmysql:execute(createSql, {}) end)
end

---@return string
local function todayUTC()
    return os.date('!%F')
end

---@return integer
local function msToNextUtcMidnight()
    local nowUTC = os.time(os.date('!*t'))
    return (86400 - (nowUTC % 86400)) * 1000
end

---@param src number
---@return string
local function identifierFor(src)
    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)
        if id and (id:find('license:') == 1 or id:find('citizenid:') == 1) then
            return id
        end
    end
    return GetPlayerIdentifier(src, 0) or tostring(src)
end

---@param vendor VendorDef
---@return string[]
local function extractUniqueItemNames(vendor)
    local names, seen = {}, {}
    for _, it in ipairs(vendor.items or {}) do
        local name = it and it.name
        if type(name) == 'string' and name ~= '' and not seen[name] then
            seen[name] = true
            names[#names + 1] = name
        end
    end
    return names
end

---@param list string[]
---@return string, string[]
local function makePlaceholders(list)
    local n = #list
    if n == 0 then return '', {} end
    local q = {}
    for i = 1, n do q[i] = '?' end
    return table.concat(q, ','), list
end

---@param rows table[]
---@return table<string, number>, table<string, number>
local function buildUsageMaps(rows)
    local usedPlayer, usedGlobal = {}, {}
    for i = 1, (rows and #rows or 0) do
        local r = rows[i]
        local scope = r and r.scope
        local item = r and r.item
        local used = tonumber(r and r.used or 0) or 0
        if scope == 'player' then
            usedPlayer[item] = used
        elseif scope == 'global' then
            usedGlobal[item] = used
        end
    end
    return usedPlayer, usedGlobal
end

---@param src number
---@param vendor VendorDef
---@return table<string, { remainingPlayer?: number, remainingGlobal?: number, cooldownMs?: number }>
function GetLimitSnapshot(src, vendor)
    local out = {}
    if not vendor then return out end

    local items = extractUniqueItemNames(vendor)
    if #items == 0 then return out end

    local day = todayUTC()
    local id = identifierFor(src)

    local placeholders = select(1, makePlaceholders(items))
    local params = { day }
    for i = 1, #items do params[#params + 1] = items[i] end
    params[#params + 1] = id

    local sql = ([[
        SELECT scope, item, SUM(quantity) AS used
        FROM peleg_vendor_limits
        WHERE day = ?
          AND item IN (%s)
          AND (scope = 'global' OR (scope = 'player' AND identifier = ?))
        GROUP BY scope, item
    ]]):format(placeholders)

    local ok, rows = pcall(function()
        return exports.oxmysql:query(sql, params)
    end)

    if not ok or type(rows) ~= 'table' then
        return out
    end

    local usedPlayer, usedGlobal = buildUsageMaps(rows)
    local cooldownMsAll = msToNextUtcMidnight()

    for _, it in ipairs(vendor.items or {}) do
        local name = it.name
        if type(name) == 'string' and name ~= '' then
            local playerLeft, globalLeft
            if it.limitPerPlayer and it.limitPerPlayer > 0 then
                local used = tonumber(usedPlayer[name] or 0) or 0
                playerLeft = math.max(0, (it.limitPerPlayer or 0) - used)
            end
            if it.limitGlobal and it.limitGlobal > 0 then
                local usedG = tonumber(usedGlobal[name] or 0) or 0
                globalLeft = math.max(0, (it.limitGlobal or 0) - usedG)
            end
            if playerLeft ~= nil or globalLeft ~= nil then
                local cdMs = ((playerLeft ~= nil and playerLeft == 0) or (globalLeft ~= nil and globalLeft == 0)) and cooldownMsAll or 0
                out[name] = { remainingPlayer = playerLeft, remainingGlobal = globalLeft, cooldownMs = cdMs }
            end
        end
    end

    return out
end

---@param src number
---@param vendor VendorDef
---@param item VendorItemDef
---@param quantity number
---@return boolean,string|nil
function CheckAndConsumeLimit(src, vendor, item, quantity)
    if not item then return false, 'Invalid item.' end
    quantity = tonumber(quantity or 0) or 0
    if quantity <= 0 then return false, 'Invalid quantity.' end

    local d = todayUTC()
    local id = identifierFor(src)

    if item.limitPerPlayer and item.limitPerPlayer > 0 then
        local row = exports.oxmysql:single('SELECT quantity FROM peleg_vendor_limits WHERE scope="player" AND identifier=? AND item=? AND day=?', { id, item.name, d })
        local used = (row and row.quantity) or 0
        if used + quantity > item.limitPerPlayer then
            return false, 'Daily player limit reached for this item.'
        end
    end

    if item.limitGlobal and item.limitGlobal > 0 then
        local rowG = exports.oxmysql:single('SELECT quantity FROM peleg_vendor_limits WHERE scope="global" AND item=? AND day=?', { item.name, d })
        local usedG = (rowG and rowG.quantity) or 0
        if usedG + quantity > item.limitGlobal then
            return false, 'Daily global limit reached for this item.'
        end
    end

    if item.limitPerPlayer and item.limitPerPlayer > 0 then
        exports.oxmysql:execute('INSERT INTO peleg_vendor_limits (scope, identifier, item, quantity, day) VALUES ("player", ?, ?, ?, ?) ON DUPLICATE KEY UPDATE quantity = quantity + VALUES(quantity)', { id, item.name, quantity, d })
    end
    if item.limitGlobal and item.limitGlobal > 0 then
        exports.oxmysql:execute('INSERT INTO peleg_vendor_limits (scope, identifier, item, quantity, day) VALUES ("global", NULL, ?, ?, ?) ON DUPLICATE KEY UPDATE quantity = quantity + VALUES(quantity)', { item.name, quantity, d })
    end

    return true
end
