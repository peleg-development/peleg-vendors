local spawned = {}
local blips = {}

local function notify(data)
    lib.notify(data)
end

---@param model string
local function ensureModel(model)
    if lib.requestModel then
        return lib.requestModel(model, 5000)
    end
    local hash = joaat(model)
    RequestModel(hash)
    local waited = 0
    while not HasModelLoaded(hash) and waited < 5000 do
        Wait(25); waited = waited + 25
    end
    return HasModelLoaded(hash)
end

---@param vendor VendorDef
local function spawnVendor(vendor)
    if not ensureModel(vendor.model) then
        print(('[peleg-vendor] Failed to load model for %s'):format(vendor.id))
        return
    end

    local ped = CreatePed(0, joaat(vendor.model), vendor.coords.x, vendor.coords.y, vendor.coords.z - 1.0, vendor.heading or 0.0, false, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    FreezeEntityPosition(ped, true)
    if vendor.scenario and vendor.scenario ~= '' then
        TaskStartScenarioInPlace(ped, vendor.scenario, 0, true)
    end

    spawned[#spawned+1] = ped

    Bridge.RegisterVendorPed(ped, vendor.id, vendor.label or 'Vendor')

    if vendor.blip and vendor.blip.enabled then
        local blip = AddBlipForCoord(vendor.coords.x, vendor.coords.y, vendor.coords.z)
        SetBlipSprite(blip, vendor.blip.sprite or 1)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, vendor.blip.scale or 0.8)
        SetBlipColour(blip, vendor.blip.color or 0)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(vendor.blip.label or vendor.label or 'Vendor')
        EndTextCommandSetBlipName(blip)
        blips[#blips+1] = blip
    end
end

CreateThread(function()
    for _, v in ipairs(Config.Vendors or {}) do
        spawnVendor(v)
    end
end)

---@param vendorId string
local function openVendor(vendorId)
    local data = lib.callback.await('peleg-vendor:getVendorData', false, vendorId)
    if data and not data.error then
        SendNUIMessage({
            type = 'vendor:open',
            vendor = data.vendor,
            stock = data.stock,
            limits = data.limits or {}
        })
        SetNuiFocus(true, true)
        notify({ type='inform', description = ('Opened vendor: %s'):format((data.vendor and data.vendor.label) or vendorId) })
    else
        notify({ type='error', description = data and (data.error or 'Failed to open.') or 'Failed to open.' })
    end
end

RegisterNetEvent('peleg-vendor:client:interact', function(vendorId)
    openVendor(vendorId)
end)

RegisterNetEvent('peleg-vendor:client:open', function(vendorId)
    openVendor(vendorId)
end)

RegisterNUICallback('vendor:requestData', function(data, cb)
    local vendorId = data and data.vendorId
    local res = lib.callback.await('peleg-vendor:getVendorData', false, vendorId)
    cb(res or { error = 'No data' })
end)

RegisterNUICallback('vendor:sell', function(data, cb)
    local vendorId = data and data.vendorId
    local name = data and data.name
    local qty = data and tonumber(data.quantity or 0) or 0

    local res = lib.callback.await('peleg-vendor:sell', false, vendorId, name, qty)
    if res and res.success then
        notify({ type='success', description = res.message or 'Sold!' })
    else
        notify({ type='error', description = (res and res.message) or 'Failed to sell.' })
    end
    cb(res or { success=false, message='No response' })
end)

RegisterNUICallback('vendor:buy', function(data, cb)
    local vendorId = data and data.vendorId
    local name = data and data.name
    local qty = data and tonumber(data.quantity or 0) or 0

    local res = lib.callback.await('peleg-vendor:buy', false, vendorId, name, qty)
    if res and res.success then
        notify({ type='success', description = res.message or 'Purchased!' })
    else
        notify({ type='error', description = (res and res.message) or 'Failed to purchase.' })
    end
    cb(res or { success=false, message='No response' })
end)

RegisterNUICallback('vendor:close', function(data, cb)
    SetNuiFocus(false, false)
    cb(true)
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    for _, ped in ipairs(spawned) do
        if DoesEntityExist(ped) then DeletePed(ped) end
    end
    for _, blip in ipairs(blips) do
        if DoesBlipExist(blip) then RemoveBlip(blip) end
    end
end)
