if not Bridge or type(Bridge) ~= 'table' then
    error('[peleg-vendor] Bridge system not initialized.')
end

local DEBUG = Config.Debug == true
local LimitsEnabled = Config.Limits and Config.Limits.Enabled == true


---@param fmt string
---@param ... any
local function dbg(fmt, ...)
    if DEBUG then
        print(('[peleg-vendor] ' .. fmt):format(...))
    end
end

---@param msg string
---@param vendorId string|nil
local function logDiscord(msg, vendorId)
    local url = Config.Webhook or ''
    if vendorId and Config.VendorWebhooks and Config.VendorWebhooks[vendorId] then
        url = Config.VendorWebhooks[vendorId]
    end
    if url == '' then return end
    PerformHttpRequest(url, function() end, 'POST', json.encode({username='peleg-vendor', content=msg}), {['Content-Type']='application/json'})
end

---@param vendorId string
---@return VendorDef|nil
local function getVendor(vendorId)
    if not vendorId then return nil end
    for _, v in ipairs(Config.Vendors) do
        if v.id == vendorId then return v end
    end
    return nil
end

---@param vendor VendorDef
---@param itemName string
---@return VendorItemDef|nil
local function findVendorItem(vendor, itemName)
    if not vendor or not itemName then return nil end
    for _, it in ipairs(vendor.items or {}) do
        if it.name == itemName then return it end
    end
    return nil
end

local busy = {}

---@param src number
---@return boolean
local function enterBusy(src)
    if busy[src] then return false end
    busy[src] = true
    return true
end

---@param src number
local function leaveBusy(src)
    busy[src] = nil
end

lib.callback.register('peleg-vendor:getVendorData', function(src, vendorId)
    local vendor = getVendor(vendorId)
    if not vendor then
        return { error = 'Vendor not found.' }
    end

    if vendor.jobRequirement and vendor.jobRequirement.job and vendor.jobRequirement.job ~= '' then
        if not Bridge.HasJobAndGrade(src, vendor.jobRequirement.job, vendor.jobRequirement.minGrade or 0) then
            return { error = 'You do not have access to this vendor.' }
        end
    end

    local names = {}
    for _, it in ipairs(vendor.items or {}) do
        names[#names+1] = it.name
    end
    local stock = Bridge.GetMultipleCounts(src, names)

    local filteredVendor = table.clone and table.clone(vendor) or json.decode(json.encode(vendor))
    do
        local jobName, grade = Bridge.GetJobAndGrade(src)
        local items = {}
        for _, it in ipairs(filteredVendor.items or {}) do
            local req = it.jobRequirement
            if req and req.job and req.job ~= '' then
                if Bridge.HasJobAndGrade(src, req.job, req.minGrade or 0) then
                    items[#items+1] = it
                end
            else
                items[#items+1] = it
            end
        end
        filteredVendor.items = items
    end

    local payload = {
        vendor = filteredVendor,
        stock = stock or {}
    }

    if LimitsEnabled then
        local identifier = lib.callback and GetPlayerIdentifier(src, 0) or ('license:' .. tostring(src))
        payload.limits = GetLimitSnapshot(src, vendor)
    end

    return payload
end)

lib.callback.register('peleg-vendor:sell', function(src, vendorId, itemName, quantity)
    if not enterBusy(src) then
        return { success = false, message = 'Action in progress, try again.' }
    end

    local ok, result = pcall(function()
        if type(itemName) ~= 'string' or itemName == '' then
            return { success = false, message = 'Invalid item name.' }
        end
        quantity = tonumber(quantity or 0) or 0
        quantity = math.floor(math.max(quantity, 0))
        if quantity <= 0 then
            return { success = false, message = 'Quantity must be greater than zero.' }
        end

        local vendor = getVendor(vendorId)
        if not vendor then
            return { success = false, message = 'Vendor not found.' }
        end
        local vItem = findVendorItem(vendor, itemName)
        if not vItem or type(vItem.price) ~= 'number' or vItem.price <= 0 then
            return { success = false, message = 'This vendor does not buy that item.' }
        end

        local have = Bridge.GetItemCount(src, itemName) or 0
        if have <= 0 then
            return { success = false, message = 'You have none of this item.' }
        end
        if quantity > have then
            quantity = have
        end

        if LimitsEnabled then
            local limOk, limMsg = CheckAndConsumeLimit(src, vendor, vItem, quantity)
            if not limOk then
                return { success = false, message = limMsg or 'Item temporarily limited.' }
            end
        end

        local removed = Bridge.RemoveItem(src, itemName, quantity)
        if not removed then
            return { success = false, message = 'Failed to remove items.' }
        end

        local payout = math.floor(vItem.price * quantity)
        if payout <= 0 then
            return { success = false, message = 'Invalid payout.' }
        end

        local paid = Bridge.AddMoney(src, payout, Config.PayoutAccount)
        if not paid then
            Bridge.AddItem(src, itemName, quantity)
            return { success = false, message = 'Failed to pay. Transaction canceled.' }
        end

        local left = Bridge.GetItemCount(src, itemName) or 0
        local playerName = GetPlayerName(src) or ('['..tostring(src)..']')
        logDiscord(('**%s** sold x%d %s to **%s** for **$%d**.'):format(playerName, quantity, itemName, vendor.label or vendor.id, payout), vendorId)
        dbg('Sold %dx %s for $%d to src=%d', quantity, itemName, payout, src)

        return { success = true, message = ('Sold %dx %s for $%d'):format(quantity, vItem.label or itemName, payout), paid = payout, left = left }
    end)

    leaveBusy(src)

    if not ok then
        dbg('Error in sell: %s', tostring(result))
        return { success = false, message = 'Internal error.' }
    end
    return result
end)

lib.callback.register('peleg-vendor:buy', function(src, vendorId, itemName, quantity)
    if not enterBusy(src) then
        return { success = false, message = 'Action in progress, try again.' }
    end

    local ok, result = pcall(function()
        if type(itemName) ~= 'string' or itemName == '' then
            return { success = false, message = 'Invalid item name.' }
        end
        quantity = tonumber(quantity or 0) or 0
        quantity = math.floor(math.max(quantity, 0))
        if quantity <= 0 then
            return { success = false, message = 'Quantity must be greater than zero.' }
        end

        local vendor = getVendor(vendorId)
        if not vendor then
            return { success = false, message = 'Vendor not found.' }
        end
        local vItem = findVendorItem(vendor, itemName)
        if not vItem or type(vItem.buyPrice) ~= 'number' or vItem.buyPrice <= 0 then
            return { success = false, message = 'This item is not buyable.' }
        end

        if vItem.jobRequirement and vItem.jobRequirement.job and vItem.jobRequirement.job ~= '' then
            if not Bridge.HasJobAndGrade(src, vItem.jobRequirement.job, vItem.jobRequirement.minGrade or 0) then
                return { success = false, message = 'You do not meet requirements.' }
            end
        end

        local cost = math.floor((vItem.buyPrice or 0) * quantity)
        if cost <= 0 then
            return { success = false, message = 'Invalid cost.' }
        end

        local removed = Bridge.RemoveMoney(src, cost, Config.PaymentAccount or 'cash')
        if not removed then
            return { success = false, message = 'Not enough funds.' }
        end

        local added = Bridge.AddItem(src, itemName, quantity)
        if not added then
            Bridge.AddMoney(src, cost, Config.PaymentAccount or 'cash')
            return { success = false, message = 'Failed to give items. Refunded.' }
        end

        local have = Bridge.GetItemCount(src, itemName) or 0
        local playerName = GetPlayerName(src) or ('['..tostring(src)..']')
        logDiscord(('**%s** bought x%d %s from **%s** for **$%d**.'):format(playerName, quantity, itemName, vendor.label or vendor.id, cost), vendorId)
        dbg('Bought %dx %s for $%d to src=%d', quantity, itemName, cost, src)

        return { success = true, message = ('Bought %dx %s for $%d'):format(quantity, vItem.label or itemName, cost), cost = cost, have = have }
    end)

    leaveBusy(src)

    if not ok then
        dbg('Error in buy: %s', tostring(result))
        return { success = false, message = 'Internal error.' }
    end
    return result
end)