AutoDetect = AutoDetect or {}

--- @param name string
--- @return boolean
function AutoDetect.IsResourceActive(name)
    if type(name) ~= 'string' or name == '' then return false end
    local state = GetResourceState(name)
    return state == 'started'
end

--- @param level '"info"'|'"warn"'|'"error"'
--- @param msg string
local function log(level, msg)
    if not Config.Debug then return end
    local prefix = '^2[peleg-vendor]^0 '
    if level == 'warn' then prefix = '^3[peleg-vendor]^0 ' end
    if level == 'error' then prefix = '^1[peleg-vendor]^0 ' end
    print(('%s%s'):format(prefix, tostring(msg)))
end

--- @return '"qb"'|'"esx"'
function AutoDetect.DetectFramework()
    local framework = Config and Config.Framework or 'auto'
    if framework ~= 'auto' then
        log('info', ('Framework override via Config: %s'):format(framework))
        return framework
    end

    if AutoDetect.IsResourceActive('qb-core') or AutoDetect.IsResourceActive('qbx_core') then
        log('info', 'Auto-detected: QBCore')
        return 'qb'
    end

    if AutoDetect.IsResourceActive('es_extended') then
        log('info', 'Auto-detected: ESX')
        return 'esx'
    end

    log('warn', 'No framework detected via resource state, defaulting to QBCore')
    return 'qb'
end

--- @return '"ox"'|'"qb"'
function AutoDetect.DetectInventory()
    local inventory = Config and Config.Inventory or 'auto'
    if inventory ~= 'auto' then
        log('info', ('Inventory override via Config: %s'):format(inventory))
        return inventory
    end

    if AutoDetect.IsResourceActive('ox_inventory') then
        log('info', 'Auto-detected: ox_inventory')
        return 'ox'
    end

    if AutoDetect.IsResourceActive('qb-inventory') then
        log('info', 'Auto-detected: qb-inventory')
        return 'qb'
    end

    log('warn', 'No inventory detected via resource state, defaulting to ox_inventory')
    return 'ox'
end

--- @return '"ox_target"'|'"qb-target"'|'"qtarget"'|'"drawtext"'
function AutoDetect.DetectTarget()
    local target = Config and Config.Target or 'auto'
    if target ~= 'auto' then
        log('info', ('Target override via Config: %s'):format(target))
        return target
    end

    if AutoDetect.IsResourceActive('ox_target') then
        log('info', 'Auto-detected: ox_target')
        return 'ox_target'
    end

    if AutoDetect.IsResourceActive('qb-target') then
        log('info', 'Auto-detected: qb-target')
        return 'qb-target'
    end

    if AutoDetect.IsResourceActive('qtarget') then
        log('info', 'Auto-detected: qtarget')
        return 'qtarget'
    end

    return 'drawtext'
end