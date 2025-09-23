---@class Bridge
Bridge = Bridge or {}

---@type '"qb"'|'"esx"'
local framework = AutoDetect.DetectFramework()

---@type '"ox"'|'"qb"'
local inventory = AutoDetect.DetectInventory()

---@type '"ox_target"'|'"qb-target"'|'"qtarget"'|'"drawtext"'
local target = AutoDetect.DetectTarget()

---@param src number
---@return table|nil
function Bridge.GetPlayer(src)
    if framework == 'qb' then
        local QBCore = exports['qb-core'] and exports['qb-core']:GetCoreObject() or nil
        return QBCore and QBCore.Functions.GetPlayer(src) or nil
    elseif framework == 'esx' then
        local ESX = exports['es_extended']:getSharedObject()
        return ESX and ESX.GetPlayerFromId(src) or nil
    end
    return nil
end

---@param src number
---@param amount number
---@param account string
---@return boolean
function Bridge.AddMoney(src, amount, account)
    amount = tonumber(amount or 0) or 0
    if amount <= 0 then return false end
    
    local player = Bridge.GetPlayer(src)
    if not player then return false end
    
    account = (account or 'cash'):lower()
    
    if account == 'auto' then
        return Bridge.AddMoneyAuto(src, amount)
    end
    
    if framework == 'qb' then
        if account == 'cash' or account == 'bank' then
            return player.Functions.AddMoney(account, amount, 'peleg-vendor-sale') == true
        elseif account == 'black_money' then
            local ok, err = pcall(function()
                return exports.ox_inventory and exports.ox_inventory:AddItem(src, 'black_money', amount) or player.Functions.AddItem('black_money', amount)
            end)
            return ok and err == true
        end
    elseif framework == 'esx' then
        if account == 'cash' then
            player.addMoney(amount)
            return true
        elseif account == 'bank' then
            player.addAccountMoney('bank', amount)
            return true
        elseif account == 'black_money' then
            player.addAccountMoney('black_money', amount)
            return true
        end
    end
    
    return false
end

---@param src number
---@param amount number
---@return boolean
function Bridge.AddMoneyAuto(src, amount)
    amount = tonumber(amount or 0) or 0
    if amount <= 0 then return false end
    
    local player = Bridge.GetPlayer(src)
    if not player then return false end
    
    if framework == 'qb' then
        return player.Functions.AddMoney('cash', amount, 'peleg-vendor-sale') == true
    elseif framework == 'esx' then
        player.addMoney(amount)
        return true
    end
    
    return false
end

---@param src number
---@param amount number
---@param account string
---@return boolean
function Bridge.RemoveMoney(src, amount, account)
    amount = tonumber(amount or 0) or 0
    if amount <= 0 then return false end

    local player = Bridge.GetPlayer(src)
    if not player then return false end

    account = (account or 'cash'):lower()

    if account == 'auto' then
        return Bridge.RemoveMoneyAuto(src, amount)
    end

    if framework == 'qb' then
        if account == 'cash' or account == 'bank' then
            return player.Functions.RemoveMoney(account, amount, 'peleg-vendor-purchase') == true
        elseif account == 'black_money' then
            local ok, removed = pcall(function()
                if exports.ox_inventory then
                    local count = exports.ox_inventory:GetItem(src, 'black_money', nil, true)
                    if (tonumber(count) or 0) < amount then return false end
                    return exports.ox_inventory:RemoveItem(src, 'black_money', amount)
                else
                    local itm = player.Functions.GetItemByName('black_money')
                    if not itm or (tonumber(itm.amount or itm.count) or 0) < amount then return false end
                    return player.Functions.RemoveItem('black_money', amount)
                end
            end)
            return ok and removed == true
        end
    elseif framework == 'esx' then
        if account == 'cash' then
            local money = player.getMoney()
            if money < amount then return false end
            player.removeMoney(amount)
            return true
        elseif account == 'bank' then
            local bank = player.getAccount('bank')
            if not bank or (tonumber(bank.money) or 0) < amount then return false end
            player.removeAccountMoney('bank', amount)
            return true
        elseif account == 'black_money' then
            local black = player.getAccount('black_money')
            if not black or (tonumber(black.money) or 0) < amount then return false end
            player.removeAccountMoney('black_money', amount)
            return true
        end
    end

    return false
end

---@param src number
---@param amount number
---@return boolean
function Bridge.RemoveMoneyAuto(src, amount)
    amount = tonumber(amount or 0) or 0
    if amount <= 0 then return false end

    local player = Bridge.GetPlayer(src)
    if not player then return false end

    if framework == 'qb' then
        local cash = player.PlayerData.money.cash or 0
        local bank = player.PlayerData.money.bank or 0
        
        if cash >= amount then
            return player.Functions.RemoveMoney('cash', amount, 'peleg-vendor-purchase') == true
        elseif (cash + bank) >= amount then
            local remaining = amount - cash
            if cash > 0 then
                if not player.Functions.RemoveMoney('cash', cash, 'peleg-vendor-purchase') then
                    return false
                end
            end
            return player.Functions.RemoveMoney('bank', remaining, 'peleg-vendor-purchase') == true
        end
    elseif framework == 'esx' then
        local cash = player.getMoney()
        local bank = player.getAccount('bank')
        local bankMoney = bank and (tonumber(bank.money) or 0) or 0
        
        if cash >= amount then
            player.removeMoney(amount)
            return true
        elseif (cash + bankMoney) >= amount then
            local remaining = amount - cash
            if cash > 0 then
                player.removeMoney(cash)
            end
            player.removeAccountMoney('bank', remaining)
            return true
        end
    end

    return false
end

---@param src number
---@return string|nil, number|nil
function Bridge.GetJobAndGrade(src)
    local player = Bridge.GetPlayer(src)
    if not player then return nil, nil end
    if framework == 'qb' then
        local job = player.PlayerData and player.PlayerData.job
        if not job then return nil, nil end
        local name = job.name
        local grade = (job.grade and (job.grade.level or job.grade)) or 0
        grade = tonumber(grade or 0) or 0
        return name, grade
    elseif framework == 'esx' then
        local job = player.job
        if not job then return nil, nil end
        local name = job.name
        local grade = tonumber(job.grade or (job.grade_level or 0)) or 0
        return name, grade
    end
    return nil, nil
end

---@param src number
---@param job string
---@param minGrade number
---@return boolean
function Bridge.HasJobAndGrade(src, job, minGrade)
    if not job or job == '' then return true end
    local name, grade = Bridge.GetJobAndGrade(src)
    if not name then return false end
    minGrade = tonumber(minGrade or 0) or 0
    return name == job and (tonumber(grade or 0) or 0) >= minGrade
end

---@param src number
---@param name string
---@return number
function Bridge.GetItemCount(src, name)
    if inventory == 'ox' then
        local ok, item = pcall(function()
            return exports.ox_inventory:GetItem(src, name, nil, true)
        end)
        if not ok or not item then return 0 end
        return type(item) == 'table' and (tonumber(item.count) or 0) or (type(item) == 'number' and item or 0)
    elseif inventory == 'qb' then
        local player = Bridge.GetPlayer(src)
        if not player then return 0 end
        local item = player.Functions.GetItemByName(name)
        return item and (tonumber(item.amount or item.count) or 0) or 0
    end
    return 0
end

---@param src number
---@param names string[]
---@return table<string, number>
function Bridge.GetMultipleCounts(src, names)
    local counts = {}
    for _, name in ipairs(names or {}) do
        counts[name] = Bridge.GetItemCount(src, name)
    end
    return counts
end

---@param src number
---@param name string
---@param amount number
---@return boolean
function Bridge.RemoveItem(src, name, amount)
    amount = math.max(0, math.floor(tonumber(amount or 0) or 0))
    if amount <= 0 then return false end
    
    if inventory == 'ox' then
        local ok, removed = pcall(function()
            return exports.ox_inventory:RemoveItem(src, name, amount)
        end)
        return ok and (removed == true or removed == 1)
    elseif inventory == 'qb' then
        local player = Bridge.GetPlayer(src)
        if not player then return false end
        return player.Functions.RemoveItem(name, amount, false, nil, 'peleg-vendor-sale') == true
    end
    
    return false
end

---@param src number
---@param name string
---@param amount number
---@return boolean
function Bridge.AddItem(src, name, amount)
    amount = math.max(0, math.floor(tonumber(amount or 0) or 0))
    if amount <= 0 then return false end
    
    if inventory == 'ox' then
        local ok, added = pcall(function()
            return exports.ox_inventory:AddItem(src, name, amount)
        end)
        return ok and (added == true or added == 1)
    elseif inventory == 'qb' then
        local player = Bridge.GetPlayer(src)
        if not player then return false end
        return player.Functions.AddItem(name, amount) == true
    end
    
    return false
end

---@param ped number
---@param vendorId string
---@param label string
function Bridge.RegisterVendorPed(ped, vendorId, label)
    if target == 'ox_target' then
        local ok, err = pcall(function()
            exports.ox_target:addLocalEntity(ped, {
                {
                    name = 'peleg-vendor:' .. vendorId,
                    icon = 'fa-solid fa-cash-register',
                    label = ('Open %s'):format(label or 'Vendor'),
                    onSelect = function()
                        TriggerEvent('peleg-vendor:client:interact', vendorId)
                    end
                }
            })
        end)
        if not ok then
            print(('[peleg-vendor] ox_target failed: %s'):format(err))
            Bridge.RegisterVendorPed(ped, vendorId, label)
        end
    elseif target == 'qb-target' then
        local ok, err = pcall(function()
            exports['qb-target']:AddTargetEntity(ped, {
                options = {
                    {
                        icon = 'fas fa-cash-register',
                        label = ('Open %s'):format(label or 'Vendor'),
                        action = function()
                            TriggerEvent('peleg-vendor:client:interact', vendorId)
                        end
                    }
                },
                distance = 2.0
            })
        end)
        if not ok then
            print(('[peleg-vendor] qb-target failed: %s'):format(err))
            Bridge.RegisterVendorPed(ped, vendorId, label)
        end
    elseif target == 'qtarget' then
        local ok, err = pcall(function()
            exports.qtarget:AddTargetEntity(ped, {
                options = {
                    {
                        icon = 'fas fa-cash-register',
                        label = ('Open %s'):format(label or 'Vendor'),
                        action = function()
                            TriggerEvent('peleg-vendor:client:interact', vendorId)
                        end
                    }
                },
                distance = 2.0
            })
        end)
        if not ok then
            print(('[peleg-vendor] qtarget failed: %s'):format(err))
            Bridge.RegisterVendorPed(ped, vendorId, label)
        end
    else
        Bridge._drawtextEntries = Bridge._drawtextEntries or {}
        local coords = GetEntityCoords(ped)
        Bridge._drawtextEntries[#Bridge._drawtextEntries+1] = {
            ped = ped,
            vendorId = vendorId,
            label = label,
            coords = coords
        }
    end
end

Bridge._drawtextEntries = Bridge._drawtextEntries or {}
Bridge._showing = false

local function draw3d(x, y, z, text)
    SetDrawOrigin(x, y, z, 0)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end

CreateThread(function()
    while true do
        if target ~= 'drawtext' or #Bridge._drawtextEntries == 0 then
            Bridge._showing = false
            Wait(500)
        else
            local ply = PlayerPedId()
            local pcoords = GetEntityCoords(ply)
            local nearest, ndist, nentry = nil, 9999.0, nil
            
            for _, e in ipairs(Bridge._drawtextEntries) do
                local dist = #(pcoords - e.coords)
                if dist < ndist then
                    ndist, nearest, nentry = dist, e.ped, e
                end
            end

            if nentry and ndist < 2.0 then
                Bridge._showing = true
                draw3d(nentry.coords.x, nentry.coords.y, nentry.coords.z + 1.0, 
                      ('~w~[~g~E~w~] Open ~y~%s~w~'):format(nentry.label or 'Vendor'))
                if IsControlJustPressed(0, 38) then -- E
                    TriggerEvent('peleg-vendor:client:interact', nentry.vendorId)
                end
                Wait(0)
            else
                Bridge._showing = false
                Wait(150)
            end
        end
    end
end)

