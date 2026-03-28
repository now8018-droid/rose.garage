Config = Config or {}
Config.garageDetail = Config.garageDetail or {}
Config.poundDetail = Config.poundDetail or {}
Config.depositvehicle = Config.depositvehicle or {}
Config.VehicleImageMap = Config.VehicleImageMap or {}

-- ===========================
-- Debug helper (wrap ทุก print)
-- ===========================
function dprint(...)
    if Config and Config.Debug then
        print(...)
    end
end

Keys 					  = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57, 
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177, 
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70, 
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}
ESX = nil;
PlayerData = nil 

CurrentPoint = nil
CurrentType = nil 

Mystored = {}
this_GaragePoint = vector3(0,0,0)
this_GarageHeading = 0
showUIDisplaytext = false 
-- showUIDisplaytext2 = false 
fistLoad = false 
OBJTUNK = nil 
openuigarage = false
GarageUiAnchorPoint = nil
GarageUiAutoCloseRadius = 0.0
createdProps = {}

local garageProgressActive = false
local cachedPlayerPed = PlayerPedId()
local lastProgressPayload = { show = nil, duration = nil, plate = nil }
local lastPoundDepositState = nil

local function getCachedPlayerPed()
    return cachedPlayerPed
end

local function distSq(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return (dx * dx) + (dy * dy) + (dz * dz)
end


local function setGarageProgressState(state, duration, plate)
    garageProgressActive = state == true

    local show = garageProgressActive
    local dur = duration or 0
    if lastProgressPayload.show == show and lastProgressPayload.duration == dur and lastProgressPayload.plate == plate then
        return
    end

    lastProgressPayload.show = show
    lastProgressPayload.duration = dur
    lastProgressPayload.plate = plate

    SendNUIMessage({
        action = 'spawnProgress',
        show = show,
        duration = dur,
        plate = plate
    })
end

local function runGarageSpawnProgress(plate, done)
    local duration = tonumber(Config.SpawnProgressDuration) or 3000
    if duration < 0 then duration = 0 end

    setGarageProgressState(true, duration, plate)

    Citizen.SetTimeout(duration, function()
        setGarageProgressState(false, 0, plate)
        if done then done() end
    end)
end

local function closeGarageUi(reason)
    if openuigarage then
        SendNUIMessage({action = 'closeui'})
    end

    openuigarage = false
    SetNuiFocus(false, false)
    CurrentPoint = nil
    CurrentType = nil
    GarageUiAnchorPoint = nil
    GarageUiAutoCloseRadius = 0.0

    if reason then
        dprint(('[garage] closeGarageUi -> %s'):format(tostring(reason)))
    end
end

local ResourceName = GetCurrentResourceName()

local function sendDiscordLog(payload)
    if type(payload) ~= 'table' then return end
    TriggerServerEvent(ResourceName..':logWebhook', payload)
end

local function notifyError()
    exports['ssr_notify']:sendAlert({
        title = 'การาจ',
        msg = 'รถคันนี้ไม่สามารถเปิดท้ายรถได้',
        type = 'error'
    })
end

local function notifyNotOwner()
    exports['ssr_notify']:sendAlert({
        title = 'การาจ',
        msg = 'คุณไม่ใช่เจ้าของรถ',
        type = 'error'
    })
end

local function canOpenTrunk(stored)
    if not stored then return false end
    if stored.type and stored.type ~= 'car' then return false end

    local ok, props = pcall(function()
        return json.decode(stored.vehicle)
    end)
    if not ok or type(props) ~= 'table' then return false end

    local model = props.model
    if not model then return false end

    local class = GetVehicleClassFromName(model)
    if class == 8 or class == 13 or class == 14 or class == 15 or class == 16 or class == 21 then
        return false
    end

    return true
end

local function decodeJsonTable(payload, fallback)
    local ok, data = pcall(function()
        return json.decode(payload or '{}')
    end)

    if ok and type(data) == 'table' then
        return data
    end

    return fallback or {}
end

local function getVehicleHealthData(storedVehicle)
    local vehicleProps = decodeJsonTable(storedVehicle and storedVehicle.vehicle)
    local health = decodeJsonTable(storedVehicle and storedVehicle.health_vehicles)

    local engine = tonumber(health.engine) or 1000.0
    local fuel = tonumber(health.fuel)
    if fuel == nil then
        fuel = tonumber(vehicleProps.fuelLevel) or 100.0
    end

    return engine, fuel
end


local function normalizePlate(plate)
    return tostring(plate or ''):gsub('^%s*(.-)%s*$', '%1'):upper()
end

local function samePlate(a, b)
    return normalizePlate(a) == normalizePlate(b)
end

local function findVehicleByPlate(plate)
    for _, vehicle in pairs(ESX.Game.GetVehicles()) do
        local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
        if vehicleProps and samePlate(vehicleProps.plate, plate) then
            return vehicle
        end
    end
    return nil
end

local function isAnyPlayerInVehicle(vehicle)
    if not vehicle or vehicle == 0 then return false end

    local maxPassengers = GetVehicleMaxNumberOfPassengers(vehicle)
    for seat = -1, maxPassengers - 1 do
        local ped = GetPedInVehicleSeat(vehicle, seat)
        if ped and ped ~= 0 and DoesEntityExist(ped) and not IsPedDeadOrDying(ped, true) and IsPedAPlayer(ped) then
            return true
        end
    end

    return false
end

local function getVehicleImageConfig(model)
    if not Config.VehicleImageMap then return nil end

    local key = string.lower(tostring(model or ''))
    if Config.VehicleImageMap[key] then
        return Config.VehicleImageMap[key]
    end

    local modelHash = tonumber(model) or GetHashKey(tostring(model or ''))
    if not modelHash or modelHash == 0 then return nil end

    local displayKey = string.lower(GetDisplayNameFromVehicleModel(modelHash) or '')
    if displayKey ~= '' and Config.VehicleImageMap[displayKey] then
        return Config.VehicleImageMap[displayKey]
    end

    for mapKey, cfg in pairs(Config.VehicleImageMap) do
        if GetHashKey(mapKey) == modelHash then
            return cfg
        end
    end

    return nil
end

Citizen.CreateThread(function()
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(l) ESX = l end)
        Citizen.Wait(200)
    end
    dprint("[garage] ESX loaded")

	Wait(1000)

	while PlayerData == nil do 
		PlayerData = ESX.GetPlayerData()
        Citizen.Wait(200)
	end 
    dprint("[garage] PlayerData loaded")

end)

CreateThread(function()
    while true do
        cachedPlayerPed = PlayerPedId()
        Wait(1000)
    end
end)

Citizen.CreateThread(function()
    while true do
        if openuigarage or garageProgressActive then
            DisableAllControlActions(0)
            DisableAllControlActions(1)
            DisableAllControlActions(2)

            Wait(0)
        else
            Wait(250)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        if openuigarage and CurrentPoint and GarageUiAnchorPoint then
            local radius = tonumber(GarageUiAutoCloseRadius) or 0.0
            if radius <= 0.0 then radius = 6.0 end

            local coords = GetEntityCoords(getCachedPlayerPed())
            if #(coords - GarageUiAnchorPoint) > radius then
                closeGarageUi('out_of_range')
                Wait(200)
            else
                Wait(200)
            end
        else
            Wait(500)
        end
    end
end)

-- ================================
-- Prop Streaming by Proximity (100m)
-- ================================
local spawnedProps = {}   -- key(string) -> entity

function loadModel(model)
    local hash = (type(model) == "string") and GetHashKey(model) or model
    if not IsModelInCdimage(hash) then
        dprint(("[PropSpawner] ❌ โมเดลไม่อยู่ในเกม: %s"):format(tostring(model)))
        return nil
    end
    RequestModel(hash)
    local t0 = GetGameTimer()
    while not HasModelLoaded(hash) do
        Wait(0)
        if GetGameTimer() - t0 > 5000 then
            dprint(("[PropSpawner] ⚠️ โหลดโมเดลนานเกิน 5 วิ: %s"):format(tostring(model)))
            break
        end
    end
    if not HasModelLoaded(hash) then return nil end
    return hash
end

function loadCollisionAt(x, y, z)
    RequestCollisionAtCoord(x + 0.0, y + 0.0, z + 0.0)
    local t = GetGameTimer()
    while not HasCollisionLoadedAroundEntity(getCachedPlayerPed()) and (GetGameTimer() - t) < 1500 do
        Wait(0)
        RequestCollisionAtCoord(x + 0.0, y + 0.0, z + 0.0)
    end
end

function findGroundZ(x, y, zHint)
    local candidates = {
        (zHint and (zHint + 50.0)) or 1000.0,
        (zHint and (zHint + 100.0)) or 800.0,
        200.0, 100.0, 70.0, 55.0, 40.0
    }

    for i = 1, #candidates do
        local testZ = candidates[i]
        loadCollisionAt(x, y, testZ)
        local ok, z = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, testZ + 0.0, false)
        if ok and z and z > -200.0 then
            return z
        end
    end

    local startZ = (zHint and (zHint + 100.0)) or 1000.0
    loadCollisionAt(x, y, startZ)
    local handle = StartExpensiveSynchronousShapeTestLosProbe(
        x + 0.0, y + 0.0, startZ + 0.0,
        x + 0.0, y + 0.0, -500.0,
        1, 0, 4
    )
    local _, hit, endCoords = GetShapeTestResult(handle)
    if hit == 1 and endCoords then
        return endCoords.z
    end
    return (zHint and zHint ~= 0.0) and zHint or 50.0
end

function ensureCollision(entity, x, y, z)
    if not HasCollisionLoadedAroundEntity(entity) then
        RequestCollisionAtCoord(x, y, z)
        local t = 0
        while not HasCollisionLoadedAroundEntity(entity) and t < 2000 do
            Wait(0)
            t = t + 1
        end
    end
end

function deleteAllZoneProps()
    for key, ent in pairs(spawnedProps) do
        if DoesEntityExist(ent) then
            SetEntityAsMissionEntity(ent, true, true)
            DeleteObject(ent)
        end
        spawnedProps[key] = nil
    end
    dprint("[PropStreamer] ♻️ cleared all streamed props")
end

function removePropForZone(zoneKey)
    local ent = spawnedProps[zoneKey]
    if ent and DoesEntityExist(ent) then
        SetEntityAsMissionEntity(ent, true, true)
        DeleteObject(ent)
        dprint(("[PropStreamer] 🗑️ STREAM-OUT '%s'"):format(zoneKey))
    end
    spawnedProps[zoneKey] = nil
end

-- หาพื้นแบบ "ใกล้ z ที่ config ใส่มา" ก่อน
local function findGroundNear(x, y, zCfg)
    -- ยิงจากเหนือจุดที่ config มานิดเดียว เผื่อ prop เฉียว ๆ
    local startZ = (zCfg or 0.0) + 2.5
    local endZ   = (zCfg or 0.0) - 10.0

    local handle = StartExpensiveSynchronousShapeTestLosProbe(
        x, y, startZ,
        x, y, endZ,
        1, 0, 4
    )
    local _, hit, endCoords = GetShapeTestResult(handle)
    if hit == 1 and endCoords then
        return true, endCoords.z
    end
    return false, zCfg
end

-- fallback ตัวใหญ่ (ยังเก็บไว้ใช้ตอนพื้นที่มันไม่มี collision ใกล้ ๆ จริง ๆ)
local function findGroundFallback(x, y, zHint)
    local startZ = (zHint or 200.0) + 100.0
    local handle = StartExpensiveSynchronousShapeTestLosProbe(
        x, y, startZ,
        x, y, -500.0,
        1, 0, 4
    )
    local _, hit, endCoords = GetShapeTestResult(handle)
    if hit == 1 and endCoords then
        return endCoords.z
    end

    local ok, z = GetGroundZFor_3dCoord(x, y, zHint or 50.0, false)
    if ok then return z end
    return zHint or 50.0
end

function spawnPropForZone(zoneKey, model, heading, coord)
    if spawnedProps[zoneKey] and DoesEntityExist(spawnedProps[zoneKey]) then return end
    if not (model and coord) then return end

    local modelHash = loadModel(model)
    if not modelHash then return end

    local x = coord.x + 0.0
    local y = coord.y + 0.0
    local z = coord.z + 0.0

    -- 1) พยายามหา “พื้นที่อยู่ใกล้ z ของ config” ก่อน
    local got, groundZ = findGroundNear(x, y, z)

    -- 2) ถ้ายิงใกล้ ๆ แล้วยังไม่เจอ ค่อย fallback ยิงยาว
    if not got then
        groundZ = findGroundFallback(x, y, z)
    end

    -- อย่า +1.0 เยอะ เดี๋ยวมันลอยบนหลังคาอีก
    local spawnZ = groundZ + 0.05

    RequestCollisionAtCoord(x, y, spawnZ)
    Wait(80)

    local ent = CreateObjectNoOffset(modelHash, x, y, spawnZ, false, false, false)
    if ent and ent ~= 0 then
        SetEntityAsMissionEntity(ent, true, true)

        -- ให้ collision มาเต็มก่อนค่อยวาง
        ensureCollision(ent, x, y, spawnZ)
        Wait(50)
        PlaceObjectOnGroundProperly(ent)

        -- ถ้ายังสูงกว่าพื้นเยอะ แสดงว่าวางบนหลังคา → บังคับลง z ที่เจอ
        local placedZ = GetEntityCoords(ent).z
        if math.abs(placedZ - groundZ) > 1.0 then
            SetEntityCoordsNoOffset(ent, x, y, groundZ + 0.05, false, false, true)
            PlaceObjectOnGroundProperly(ent)
        end

        SetEntityHeading(ent, tonumber(heading or 0.0))
        SetEntityCollision(ent, true, true)
        FreezeEntityPosition(ent, true)
        SetEntityInvincible(ent, true)
        spawnedProps[zoneKey] = ent

        dprint(("[PropStreamer] ✅ %s @ %.2f, %.2f, %.2f"):format(zoneKey, x, y, GetEntityCoords(ent).z))
    else
        dprint(("[PropStreamer] ❌ spawn fail %s @ %s"):format(model, zoneKey))
    end

    SetModelAsNoLongerNeeded(modelHash)
end


local PropZones = {}  -- array ของ { key, coord, model, heading }

function pushZone(key, coord, propTbl)
    if propTbl and propTbl.model and coord then
        PropZones[#PropZones+1] = {
            key     = key,
            coord   = coord,
            model   = propTbl.model,
            heading = propTbl.heading or 0.0
        }
    end
end

function buildPropZonesFromConfig()
    PropZones = {}

    for idx, v in ipairs(Config.garageDetail or {}) do
        local baseName = v.name or ("garage_"..idx)
        if v.Propspawn then
            pushZone(("garage:%s:spawn:%d"):format(baseName, idx), v.location, v.Propspawn)
        end
        if v.Propdelete then
            local delLoc = v.deletelocation or v.location
            pushZone(("garage:%s:delete:%d"):format(baseName, idx), delLoc, v.Propdelete)
        end
    end

    for idx, v in ipairs(Config.poundDetail or {}) do
        local lbl = v.name or ("pound_"..idx)
        if v.Propspawn then
            pushZone(("pound:%s:%d"):format(lbl, idx), v.location, v.Propspawn)
        end
    end

    for idx, v in ipairs(Config.depositvehicle or {}) do
        local lbl = v.Label or ("deposit_"..idx)
        if v.Propspawn then
            pushZone(("deposit:%s:spawn:%d"):format(lbl, idx), v.location, v.Propspawn)
        end
        if v.Propdelete then
            local delLoc = v.deletelocation or v.location
            pushZone(("deposit:%s:delete:%d"):format(lbl, idx), delLoc, v.Propdelete)
        end
    end

    dprint(("[PropStreamer] Zones ready: %d"):format(#PropZones))
end

local STREAM_RADIUS = 100.0
local STREAM_RADIUS_SQ = STREAM_RADIUS * STREAM_RADIUS
local TICK_MS       = 1000

CreateThread(function()
    buildPropZonesFromConfig()

    while true do
        Wait(TICK_MS)

        cachedPlayerPed = PlayerPedId()
        local ped = cachedPlayerPed
        local ppos  = GetEntityCoords(ped)

        for i = 1, #PropZones do
            local zdef = PropZones[i]
            local d2 = distSq(ppos, zdef.coord)
            local has  = spawnedProps[zdef.key] and DoesEntityExist(spawnedProps[zdef.key])
            if d2 <= STREAM_RADIUS_SQ then
                if not has then
                    spawnPropForZone(zdef.key, zdef.model, zdef.heading, zdef.coord)
                end
            else
                if has then
                    removePropForZone(zdef.key)
                end
            end
        end
    end
end)

AddEventHandler("onResourceStop", function(res)
    if res == GetCurrentResourceName() then
        deleteAllZoneProps()
    end
end)

RegisterNetEvent(ResourceName..':reloadData:client')
AddEventHandler(ResourceName..':reloadData:client', function(vehicle)
    if Config.pounddeposit ~= nil and lastPoundDepositState ~= Config.pounddeposit then
        lastPoundDepositState = Config.pounddeposit
        SendNUIMessage({action = 'pounddeposit', pounddeposit = Config.pounddeposit})
    end
    Mystored = vehicle
    fistLoad = true
    
    dprint(("[garage] reloadData received: %d vehicles"):format(#(Mystored or {})))
end)

RegisterNetEvent("esx:setJob")
AddEventHandler("esx:setJob", function(job)
    while PlayerData == nil do 
        Citizen.Wait(10)
    end
    dprint('[garage] Job Update -> '..(job and job.name or 'nil'))
	PlayerData.job = job
	Citizen.Wait(3000)
end)

exports('getVehicleData',function(plate)
    if not fistLoad then
        TriggerServerEvent(ResourceName..':reloadData') 
        while fistLoad do 
            Wait(100)
        end 
        Wait(200)
    end 
    for _ , v in pairs(Mystored) do 
        if samePlate(v.plate, plate) then
            local vehiclemodel = json.decode(v.vehicle).model 
            local vehiclename = GetDisplayNameFromVehicleModel(vehiclemodel)
            return vehiclename , v.stored
        end 
    end  
    return 'Unknow' ,  false 
end)

exports('getVehicleMoel',function(plate)
    if not fistLoad then
        TriggerServerEvent(ResourceName..':reloadData') 
        while fistLoad do 
            Wait(100)
        end 
    end 
    for _ , v in pairs(Mystored) do 
        if samePlate(v.plate, plate) then
            local vehiclemodel = json.decode(v.vehicle).model 
            return vehiclemodel
        end 
    end  
    return false 
end)

exports('GetVehicleProperties', function(vehicle)
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        return nil
    end

    if not ESX or not ESX.Game or not ESX.Game.GetVehicleProperties then
        return nil
    end

    local ok, props = pcall(function()
        return ESX.Game.GetVehicleProperties(vehicle)
    end)

    if ok and type(props) == 'table' then
        return props
    end

    return nil
end)

checkCanDeposit = function(plate,vehicle,id) 
    for _ , v in pairs(Mystored) do 
        local vehiclemodel = json.decode(v.vehicle) 
        if samePlate(v.plate, plate) and vehiclemodel.model == vehicle.model and v.deposit == nil then
            Mystored[_].deposit = id
            return Mystored[_] 
        end 
    end 
    return false
end

StoreVehicle_deposit = function (id_deposit)
    Citizen.CreateThread(function()
        local playerPed  = PlayerPedId()
        local vehicle =	GetVehiclePedIsIn(playerPed, false)       
        local vehicleProps  = ESX.Game.GetVehicleProperties(vehicle)        
        local tableVehicle = checkCanDeposit(vehicleProps.plate, vehicleProps, id_deposit)
        if tableVehicle then
            SaveDamage(vehicle, vehicleProps)
            sendDiscordLog({
                webhook = 'storevehicle',
                action = 'storevehicle',
                plate = vehicleProps.plate,
                durability = math.floor(GetVehicleEngineHealth(vehicle) or 0),
                fuel = math.floor((vehicleProps.fuelLevel or GetVehicleFuelLevel(vehicle) or 0) + 0.5)
            })
            dprint(('Deposit: %s deposited plate %s at deposit ID %s'):format(PlayerData.identifier or "unknown", vehicleProps.plate, id_deposit))
            if Config.depositvehicle[id_deposit].autodelete then
                SetEntityCoords(playerPed, Config.depositvehicle[id_deposit].deletelocation)
            end
            -- print(ESX.DumpTable(Config.depositvehicle[id_deposit]))
            TriggerServerEvent(ResourceName..':depositvehicles', vehicleProps.plate, id_deposit)
            ESX.Game.DeleteVehicle(vehicle)
        end   
        CurrentPoint = nil 
    end)
end

checkOwner = function(plate,model)
    for _ , v in pairs(Mystored) do
        local vehiclemodel = json.decode(v.vehicle).model 
        if samePlate(v.plate, plate) and (vehiclemodel == model or GetDisplayNameFromVehicleModel(model):lower() == vehiclemodel) then
            v.stored = true 
            return true 
        end 
    end 
    return false 
end

-- getTableSpawn = function(plate,current_type) 
--     local stored = false
--     if (CurrentPoint == 'garage') then
--         stored = true 
--     end 
--     for _ , v in pairs(Mystored) do 
--         if samePlate(v.plate, plate) and v.stored == stored then
--             if stored then
--                 v.stored = not stored
--             end
--             return v 
--         end 
--     end 
--     return false 
-- end 
getTableSpawn = function(plate,current_type)
    for _ , v in pairs(Mystored) do
        if samePlate(v.plate, plate) then
            return v
        end
    end
    return false
end

removeDeposit = function(plate)
    -- print('removeDeposit', plate)\
    for _ , v in pairs(Mystored) do
        if samePlate(v.plate, plate) and v.deposit ~= nil then
            local num = v.deposit
            Mystored[_].deposit = nil 
            return num
        end 
    end 
    return false 
end 

openGarage = function(current_point,current_type,job)

    local vehicle_detail = {}
    -- print('openGarage', current_point, current_type, job)
    if current_point ~= 'deposit' then
        -- print(ESX.DumpTable(Mystored))
        for _ , v in pairs(Mystored) do
            if current_type == v.type then
                local vehiclemodel = json.decode(v.vehicle).model 
                local visualCfg = getVehicleImageConfig(vehiclemodel)
                local vehiclename = (visualCfg and visualCfg.name) or GetDisplayNameFromVehicleModel(vehiclemodel)
                local healthEngine, fuel = getVehicleHealthData(v)
                local maxSpeed = (GetVehicleModelEstimatedMaxSpeed(vehiclemodel)/GetVehicleClassEstimatedMaxSpeed(GetVehicleClassFromName(vehiclemodel)))*100
                local maxBreak = (GetVehicleModelMaxBraking(vehiclemodel)/GetVehicleClassMaxBraking(GetVehicleClassFromName(vehiclemodel)))*100
                local maxAcc = (GetVehicleModelAcceleration(vehiclemodel)/GetVehicleClassMaxAcceleration(GetVehicleClassFromName(vehiclemodel)))*100
                if v.vehiclename ~= nil then
                    vehiclename = v.vehiclename
                end 
                if job ~= nil then
                    if job and type(job) == 'table' then
                        for _ , j in pairs(job) do
                            if j == v.job then
                                table.insert(vehicle_detail,{
                                    plate = v.plate,
                                    stored = v.stored,
                                    police = v.police,
                                    vehiclename = vehiclename,
                                    engine = healthEngine/10,
                                    fuel = fuel,
                                    modelname = (visualCfg and visualCfg.name) or GetDisplayNameFromVehicleModel(vehiclemodel),
                                    weight = 0,
                                    class = GetCarTypeToNui(vehiclemodel),
                                    img = GetCarTypeToNuiImage(vehiclemodel),
                                    maxspeed = maxSpeed,
                                    maxbreak =maxBreak,
                                    maxacc = maxAcc
                                })
                            end 
                        end
                    else
                        if job == v.job then
                            table.insert(vehicle_detail,{
                                plate = v.plate,
                                stored = v.stored,
                                police = v.police,
                                vehiclename = vehiclename,
                                engine = healthEngine/10,
                                fuel = fuel,
                                modelname = (visualCfg and visualCfg.name) or GetDisplayNameFromVehicleModel(vehiclemodel),
                                weight = 0,
                                class = GetCarTypeToNui(vehiclemodel),
                                img = GetCarTypeToNuiImage(vehiclemodel),
                                maxspeed = maxSpeed,
                                maxbreak =maxBreak,
                                maxacc = maxAcc
                            })
                        end 
                    end
                else 
                    if current_point == 'garage' then
                        if v.job == '' then
                            table.insert(vehicle_detail,{
                                plate = v.plate,
                                stored = v.stored,
                                police = v.police,
                                vehiclename = vehiclename,
                                engine = healthEngine/10,
                                fuel = fuel,
                                modelname = (visualCfg and visualCfg.name) or GetDisplayNameFromVehicleModel(vehiclemodel),
                                weight = 0,
                                class = GetCarTypeToNui(vehiclemodel),
                                img = GetCarTypeToNuiImage(vehiclemodel),
                                maxspeed = maxSpeed,
                                maxbreak = maxBreak,
                                maxacc = maxAcc
                            })
                            if v.deposit then
                                for key, value in pairs(Config.depositvehicle) do 
                                    if key == v.deposit then
                                        vehicle_detail[#vehicle_detail].deposit = value.Label
                                        -- vehicle_detail[#vehicle_detail].stored = true
                                        break
                                    end
                                end
                            end
                        end
                    else 
                        table.insert(vehicle_detail, {
                            plate = v.plate,
                            stored = v.stored,
                            police = v.police,
                            vehiclename = vehiclename,
                            engine = healthEngine / 10,
                            fuel = fuel,
                            modelname = (visualCfg and visualCfg.name) or GetDisplayNameFromVehicleModel(vehiclemodel),
                            weight = 0,
                            class = GetCarTypeToNui(vehiclemodel),
                            img = GetCarTypeToNuiImage(vehiclemodel),
                            maxspeed = maxSpeed,
                            maxbreak = maxBreak,
                            maxacc = maxAcc
                        })
                        if v.deposit then
                            for key, value in pairs(Config.depositvehicle) do 
                                if key == v.deposit then
                                    vehicle_detail[#vehicle_detail].deposit = value.Label
                                    vehicle_detail[#vehicle_detail].stored = true
                                    break
                                end
                            end
                        end
                    end 
                end 
            end
        end 
    else 
        for _ , v in pairs(Mystored) do
            if v.deposit ~= nil and v.deposit == current_type then
                local vehiclemodel = json.decode(v.vehicle).model
                local visualCfg = getVehicleImageConfig(vehiclemodel)
                local vehiclename = (visualCfg and visualCfg.name) or GetDisplayNameFromVehicleModel(vehiclemodel)
                local healthEngine, fuel = getVehicleHealthData(v)
                local maxSpeed = (GetVehicleModelEstimatedMaxSpeed(vehiclemodel)/GetVehicleClassEstimatedMaxSpeed(GetVehicleClassFromName(vehiclemodel)))*100
                local maxBreak = (GetVehicleModelMaxBraking(vehiclemodel)/GetVehicleClassMaxBraking(GetVehicleClassFromName(vehiclemodel)))*100
                local maxAcc = (GetVehicleModelAcceleration(vehiclemodel)/GetVehicleClassMaxAcceleration(GetVehicleClassFromName(vehiclemodel)))*100
                if v.vehiclename ~= nil then
                    vehiclename = v.vehiclename
                end 
                table.insert(vehicle_detail,{
                    plate = v.plate,
                    stored = v.stored,
                    police = v.police,
                    vehiclename = vehiclename,
                    engine = healthEngine/10,
                    fuel = fuel,
                    modelname = (visualCfg and visualCfg.name) or GetDisplayNameFromVehicleModel(vehiclemodel),
                    class = GetCarTypeToNui(vehiclemodel),
                    weight = 0,
                    img = GetCarTypeToNuiImage(vehiclemodel),
                    maxspeed = maxSpeed,
                    maxbreak =maxBreak,
                    maxacc = maxAcc,
                })
            end
        end 
    end 

    SendNUIMessage({
        action = "syncData",
        type = current_point,
        data = vehicle_detail
    })
    SendNUIMessage({action =  'open'})
    openuigarage = true
    SetNuiFocus(true, true)

    dprint(("[garage] openGarage -> point=%s type=%s items=%d"):format(tostring(current_point), tostring(current_type), #vehicle_detail))
end

GetCarTypeToNui = function(veh)
	local vc = GetVehicleClassFromName(veh)
	if vc == 8 then
		return 'Motocycle'
	elseif vc == 14 then
		return 'Boat'
	elseif vc == 16 then
		return 'Plane'
	elseif vc == 15 then
		return 'Helicopter'
	else
        if vc == 0 then
            return 'Compacts'
        elseif vc == 1 then
            return 'Sedans'
        elseif vc == 2 then
            return 'SUVs'
        elseif vc == 3 then
            return 'Coupes'
        elseif vc == 4 then
            return 'Muscle'
        elseif vc == 5 then
            return 'Sports C'
        elseif vc == 6 then
            return 'Sports'
        elseif vc == 7 then
            return 'Super'
        elseif vc == 8 then
            return 'Motorcycles'
        elseif vc == 9 then
            return 'Off-road'
        elseif vc == 12 then
            return 'Vans'
        elseif vc == 18 then
            return 'Emergency'
        end 
	end
    return 'OTHER'
end

ReloadVehicleData = function(current_point,current_type)
    local vehicle_detail = {}
    if current_point ~= 'deposit' then
        for _ , v in pairs(Mystored) do 
            if current_type == v.type then
                local vehiclemodel = json.decode(v.vehicle).model 
                local vehiclename = GetDisplayNameFromVehicleModel(vehiclemodel)
                local healthEngine, fuel = getVehicleHealthData(v)
                local maxSpeed = (GetVehicleModelEstimatedMaxSpeed(vehiclemodel)/GetVehicleClassEstimatedMaxSpeed(GetVehicleClassFromName(vehiclemodel)))*100
                local maxBreak = (GetVehicleModelMaxBraking(vehiclemodel)/GetVehicleClassMaxBraking(GetVehicleClassFromName(vehiclemodel)))*100
                local maxAcc = (GetVehicleModelAcceleration(vehiclemodel)/GetVehicleClassMaxAcceleration(GetVehicleClassFromName(vehiclemodel)))*100
                if v.vehiclename ~= nil then
                    vehiclename = v.vehiclename
                end 
                table.insert(vehicle_detail,{
                    plate = v.plate,
                    stored = v.stored,
                    police = v.police,
                    vehiclename = vehiclename,
                    engine = healthEngine/10,
                    fuel = fuel,
                    modelname = (visualCfg and visualCfg.name) or GetDisplayNameFromVehicleModel(vehiclemodel),
                    class = GetCarTypeToNui(vehiclemodel),
                    img = GetCarTypeToNuiImage(vehiclemodel),
                    weight = 0,
                    maxspeed = maxSpeed,
                    maxbreak =maxBreak,
                    maxacc = maxAcc
                })
            end
        end 
    else 
        for _ , v in pairs(Mystored) do 
            if v.deposit ~= nil then
                local vehiclemodel = json.decode(v.vehicle).model 
                local visualCfg = getVehicleImageConfig(vehiclemodel)
                local vehiclename = (visualCfg and visualCfg.name) or GetDisplayNameFromVehicleModel(vehiclemodel)
                local healthEngine, fuel = getVehicleHealthData(v)
                local maxSpeed = (GetVehicleModelEstimatedMaxSpeed(vehiclemodel)/GetVehicleClassEstimatedMaxSpeed(GetVehicleClassFromName(vehiclemodel)))*100
                local maxBreak = (GetVehicleModelMaxBraking(vehiclemodel)/GetVehicleClassMaxBraking(GetVehicleClassFromName(vehiclemodel)))*100
                local maxAcc = (GetVehicleModelAcceleration(vehiclemodel)/GetVehicleClassMaxAcceleration(GetVehicleClassFromName(vehiclemodel)))*100
                if v.vehiclename ~= nil then
                    vehiclename = v.vehiclename
                end 
                table.insert(vehicle_detail,{
                    plate = v.plate,
                    stored = v.stored,
                    police = v.police,
                    vehiclename = vehiclename,
                    engine = healthEngine/10,
                    fuel = fuel,
                    modelname = (visualCfg and visualCfg.name) or GetDisplayNameFromVehicleModel(vehiclemodel),
                    class = GetCarTypeToNui(vehiclemodel),
                    weight = 0,
                    img = GetCarTypeToNuiImage(vehiclemodel),
                    maxspeed = maxSpeed,
                    maxbreak =maxBreak,
                    maxacc = maxAcc
                })
            end
        end 
    end
    SendNUIMessage({
        action = "syncData",
        type = current_point,
        data = vehicle_detail
    })
    dprint(("[garage] ReloadVehicleData -> point=%s type=%s items=%d"):format(tostring(current_point), tostring(current_type), #vehicle_detail))
end 

-- RegisterCommand('Mystored',function()
--     print('===================')
--     print(ESX.DumpTable(Mystored))
--     print('===================')
-- end)

-- RegisterNetEvent(ResourceName..':addVehicle')
-- AddEventHandler(ResourceName..':addVehicle', function(vehicle)
--     for _ , v in pairs(Mystored) do
--         if v.plate == vehicle.plate then
--             return
--         end 
--     end
--     -- table.insert(Mystored, vehicle)
--     for add_key, add_value in pairs(vehicle) do
--         table.insert(Mystored, add_value)
        
--     end
--     dprint(("[garage] addVehicle %s"):format(vehicle.plate or "unknown"))
-- end)
RegisterNetEvent(ResourceName..':addVehicle')
AddEventHandler(ResourceName..':addVehicle', function(vehData)
    -- ป้องกัน vehData เป็น nil/boolean โดยผิดพลาด
    if type(vehData) ~= "table" then
        dprint("[garage] addVehicle got invalid data (not table)")
        return
    end

    if not vehData.plate then
        dprint("[garage] addVehicle missing plate")
        return
    end

    local okDecode, props = pcall(function()
        return json.decode(vehData.vehicle or '{}')
    end)
    if not okDecode or type(props) ~= 'table' then
        props = {}
    end

    if not vehData.vehiclename or vehData.vehiclename == '' then
        local displayName = props.model and GetDisplayNameFromVehicleModel(props.model) or nil
        vehData.vehiclename = displayName or tostring(props.model or 'UNKNOWN')
    end

    if not vehData.health_vehicles then
        vehData.health_vehicles = json.encode({
            engine = 1000.0,
            fuel = tonumber(props.fuelLevel or 100.0) or 100.0,
            health_body = 1000.0,
            tyres = {},
            doors = {}
        })
    end

    -- ถ้า Mystored ยังไม่ถูกสร้าง ให้สร้างเป็น table ว่าง
    if not fistLoad then
        TriggerServerEvent(ResourceName..':reloadData')
        while not fistLoad do Wait(0) end
    end

    -- กันซ้ำด้วย plate
    for _, v in pairs(Mystored) do
        if type(v) == "table" and samePlate(v.plate, vehData.plate) then
            dprint(("[garage] vehicle %s already exists in Mystored, skip"):format(vehData.plate))
            return
        end
    end

    -- push เข้า Mystored ตรง ๆ เป็นหนึ่งคัน
    table.insert(Mystored, vehData)

    dprint(("[garage] addVehicle %s OK"):format(vehData.plate))
end)


RegisterNetEvent(ResourceName..':removeVehicle')
AddEventHandler(ResourceName..':removeVehicle', function(plate)
    for key, vehicle in pairs(ESX.Game.GetVehicles()) do
		local vehicleProps  = ESX.Game.GetVehicleProperties(vehicle)
		if vehicleProps.plate == plate then
			SetVehicleHasBeenOwnedByPlayer(vehicle, false) 
			SetEntityAsMissionEntity(vehicle, false, false) 
            ESX.Game.DeleteVehicle(vehicle)
            break
		end
	end
    for _ , v in pairs(Mystored) do 
        if samePlate(v.plate, plate) then
            Mystored[_] = nil
            break
        end 
    end 
    dprint(("[garage] removeVehicle %s"):format(plate))
end)

RegisterNetEvent(ResourceName..':SetVehToGarage')
AddEventHandler(ResourceName..':SetVehToGarage', function(plate)
    for _ , v in pairs(Mystored) do 
        if samePlate(v.plate, plate) then
            Mystored[_].stored = true
            TriggerEvent('pNotify:SendNotification', {
                text = 'ย้ายรถ ทะเบียน'..plate..'เข้าการาจเรียบร้อย',
                type = 'success',
                timeout = 3000,
                layout = 'centerRight'
            })
            break
        end 
    end
end)

function StoreOwnedVehicleMenu()
	local playerPed  = PlayerPedId()
	local vehicle =	GetVehiclePedIsIn(playerPed, false)
    if vehicle == 0 then
        CurrentPoint = nil
        return
    end

	local vehicleProps  = ESX.Game.GetVehicleProperties(vehicle)
    if not vehicleProps or not vehicleProps.plate then
        CurrentPoint = nil
        return
    end

    if checkOwner(vehicleProps.plate,vehicleProps.model) then
        sendDiscordLog({
            webhook = 'storevehicle',
            action = 'storevehicle',
            plate = vehicleProps.plate,
            durability = math.floor(GetVehicleEngineHealth(vehicle) or 0),
            fuel = math.floor((vehicleProps.fuelLevel or GetVehicleFuelLevel(vehicle) or 0) + 0.5)
        })

-- * optional หมายถึงจะใส่หรือไม่ใส่ก็ได้
        TaskLeaveVehicle(playerPed,vehicle,0)
        SaveDamage(vehicle, vehicleProps)
        TriggerServerEvent(ResourceName..':setStateVehicle', vehicleProps.plate, true, vehicleProps)
        ESX.Game.DeleteVehicle(vehicle)
        dprint(("[garage] storeOwned -> %s"):format(vehicleProps.plate))
    else
        notifyNotOwner()
    end
    CurrentPoint = nil
end

RegisterNetEvent(ResourceName..':deletePoundVehicleAll')
AddEventHandler(ResourceName..':deletePoundVehicleAll', function(plates)
	SpawnPoundDelete(plates)
end)

function SpawnPoundDelete(plate)
    if ESX == nil then
        dprint("🚫 ESX is nil in SpawnPoundDelete")
        return
    end
    -- while not ESX.IsPlayerLoaded do 
    --     Wait(0)
    -- end

    for key, vehicle in pairs(ESX.Game.GetVehicles()) do
        local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
        if not vehicleProps then
            dprint("🚫 vehicleProps is nil for vehicle in SpawnPoundDelete")
            return
        end
        if vehicleProps.plate == plate then
            local netId = NetworkGetNetworkIdFromEntity(vehicle)
            NetworkRequestControlOfEntity(vehicle)

            local attempts = 0
            while not NetworkHasControlOfEntity(vehicle) and attempts < 100 do
                Wait(10)
                NetworkRequestControlOfEntity(vehicle)
                attempts = attempts + 1
            end

            if NetworkHasControlOfEntity(vehicle) then
                dprint(("✅ remove car (pound): %s"):format(plate))
                SetVehicleHasBeenOwnedByPlayer(vehicle, false)
                SetEntityAsMissionEntity(vehicle, true, true)
                ESX.Game.DeleteVehicle(vehicle)
            else
                dprint(("🚫 remove error (no control): %s"):format(plate))
            end
        end
    end
end

-- local WhitelistDimen = Config.WhitelistDimen

function isWhitelistedDimension(dim)
    local WhitelistDimen = exports['val-setdimention']:GetWhitelistDimen()
    for _, allowed in ipairs(WhitelistDimen) do
        if dim == allowed then
            return true
        end
    end
    return false
end

function SpawnVehicle(vehicle, plate, damage)
	local cb_veh = nil
    local model = vehicle.model
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end

    local myDim = exports['val-setdimention']:GetDimension()
    if myDim ~= 0 and not isWhitelistedDimension(myDim) then
        exports['val-setdimention']:SetDimension(0)
        Wait(500)
    end
    -- while exports['val-setdimention']:GetDimension() ~= 0 do
    --     exports['val-setdimention']:SetDimension(0)
    --     Wait(100)
    -- end


    local frist = false 
    if not frist then
        frist = true 
        SetEntityCoords(PlayerPedId(),this_GaragePoint)
    end

    SetEntityHeading(PlayerPedId(),this_GarageHeading)
    
	ESX.Game.SpawnVehicle(model, this_GaragePoint, this_GarageHeading, function(callback_vehicle)
		ESX.Game.SetVehicleProperties(callback_vehicle, vehicle)
		cb_veh = callback_vehicle
		TaskWarpPedIntoVehicle(PlayerPedId(), callback_vehicle, -1)
        SetPedIntoVehicle(PlayerPedId(), callback_vehicle, -1)
		SetVehRadioStation(callback_vehicle, "OFF")
		SetDamage(callback_vehicle, damage)
		SetLocalPlayerAsGhost(true)
        
        local Getplate = GetVehicleNumberPlateText(callback_vehicle)
        SpawnVehicleLast(model, Getplate)      
		Wait(10)
		local veh = GetVehiclePedIsUsing(PlayerPedId())
		SetEntityAlpha(veh, 121, false)
        exports['val-legacyfuel']:SetFuel(veh, vehicle.fuelLevel)

		Wait(6000)
		ResetEntityAlpha(veh)
        exports['val-legacyfuel']:SetFuel(veh, vehicle.fuelLevel)
        dprint(("[garage] SpawnVehicle -> %s fuel=%s"):format(tostring(Getplate), tostring(vehicle.fuelLevel)))

		SetLocalPlayerAsGhost(false)
	end)
    TriggerServerEvent(ResourceName..':setStateVehicle', plate, false)
    CurrentPoint = nil 
end

RegisterNUICallback('trunkopen', function(data,cb)
    for _ , v in pairs(Mystored) do
        if samePlate(v.plate, data.plate) then
            if not canOpenTrunk(v) then
                notifyError()
                cb('fail')
                return
            end

            if exports["mythic_progbar"]:isDoingAction() then
                TriggerEvent('pNotify:SendNotification', { type = 'error', text = 'กรุณาลองใหม่ภายหลัง' })
                return
            end
            
            TriggerEvent("mythic_progbar:client:progress", {
                duration = 3000,
                useWhileDead = true,
                canCancel = false,
                label = '',
                controlDisables = {
                    disableMovement = true,
                    disableCarMovement = true,
                    disableMouse = false,
                    disableCombat = true,
                }
            }, function(status)
                if not status then
                    TriggerServerEvent(ResourceName..':openTrunk', data.plate)
                    dprint(("[garage] trunkopen -> %s"):format(data.plate))
                end
            end,'none')
        end 
    end 
    openuigarage = false
    SetNuiFocus(false,false)
    cb('success')
    Wait(1500)
    CurrentPoint = nil
end)

function MakeEntityFaceCoord(entity1, Coord)
    local p1 = GetEntityCoords(entity1, true)
    local dx = Coord.x - p1.x
    local dy = Coord.y - p1.y
    local heading = GetHeadingFromVector_2d(dx, dy)
    SetEntityHeading(entity1, heading)
end

function IsVehicleFacingAway(vehicle, targetCoord)
    local vehicleHeading = GetEntityHeading(vehicle) 
    local vehiclePos = GetEntityCoords(vehicle) 
    local targetHeading = GetHeadingFromVector_2d(targetCoord.x - vehiclePos.x, targetCoord.y - vehiclePos.y)
    local headingDifference = math.abs(vehicleHeading - targetHeading)
    return headingDifference > 90
end

function Create(data)
    RequestModel(data.model)
    repeat Wait(0) until HasModelLoaded(data.model)
	local vehicle = CreateVehicle(data.model, GetEntityCoords(PlayerPedId()), 0.0, false, false)
    ESX.Game.SetVehicleProperties(vehicle, data)
    SetEntityVisible(vehicle, false, 0)
	SetVehicleIsConsideredByPlayer(vehicle, false)
	SetEntityCollision(vehicle, false, false)
    SetEveryoneIgnorePlayer(vehicle, false)
    SetPoliceIgnorePlayer(vehicle, false)
	return vehicle
end

local delayCheck = false 
RegisterNUICallback('spawnvehicle', function(data,cb)
    local tableData = getTableSpawn(data.plate)
    if not tableData then
        cb('fail')
        return
    end

    if delayCheck then
        cb('fail')
        return
    end

    local damage = decodeJsonTable(tableData.health_vehicles)
    local vehicleProps = decodeJsonTable(tableData.vehicle)

    damage.engine = tonumber(damage.engine) or 1000.0
    damage.health_body = tonumber(damage.health_body) or 1000.0
    damage.fuel = tonumber(damage.fuel)
    if damage.fuel == nil then
        damage.fuel = tonumber(vehicleProps.fuelLevel) or 100.0
    end

    if type(damage.tyres) ~= 'table' then
        damage.tyres = {}
    end

    if type(damage.doors) ~= 'table' then
        damage.doors = {}
    end

    if CurrentPoint == 'pound' then
        local worldVehicle = findVehicleByPlate(data.plate)
        if worldVehicle and isAnyPlayerInVehicle(worldVehicle) then
            dprint(("[garage] cannot pound vehicle %s: someone is in vehicle"):format(tostring(data.plate)))
            Config.notification('error', 'ไม่สามารถพาวน์ได้ เนื่องจากมีคนอยู่บนรถ')
            cb('fail')
            return
        end

        delayCheck = true
        ESX.TriggerServerCallback(ResourceName..':payMoney', function(hasEnoughMoney)
            if not hasEnoughMoney then
                TriggerEvent('pNotify:SendNotification', { type = 'error', text = 'คุณไม่มีเงินพอที่จะจ่ายค่าพาวรถ' })
                Wait(2000)
                delayCheck = false
                cb('nomoney')
                return
            end

            cb('success')
            damage.engine = Config.healthPound*10
            damage.health_body = Config.healthPound
            damage.fuel = Config.fuelPound

            if damage.tyres then
                for tyreId = 1, 7, 1 do
                    if damage.tyres[tyreId] ~= false then
                        damage.tyres[tyreId] = false
                    end
                end
            end

            if damage.doors then
                for doorId = 0, 5, 1 do
                    damage.doors[doorId] = false
                end
            end

            if Config.pounddeposit then
                local data_id = removeDeposit(data.plate)
                if data_id then
                    TriggerServerEvent(ResourceName..':removeDepositCar', data.plate,data_id)
                end
            end

            for _ , w in pairs(Mystored) do
                if w.plate == data.plate and w.deposit ~= nil then
                    Mystored[_].deposit = nil
                end
            end

            TriggerServerEvent(ResourceName..':deletePoundVehicle', tableData.plate)
            runGarageSpawnProgress(data.plate, function()
                openuigarage = false
                SetNuiFocus(false,false)
                SendNUIMessage({action = 'closeui'})
                CurrentPoint = nil
                SpawnVehicle(json.decode(tableData.vehicle),tableData.plate,damage)
                Wait(1000)
                sendDiscordLog({
                    webhook = 'garage_pound',
                    action = 'garage_pound',
                    plate = tableData.plate,
                    durability = math.floor(damage.engine or 0),
                    fuel = math.floor((damage.fuel or 0) + 0.5)
                })
                dprint(("[garage] spawnvehicle (pound) -> %s"):format(tableData.plate))
            end)
        end)

    elseif CurrentPoint == 'deposit' then
        cb('success')
        runGarageSpawnProgress(data.plate, function()
            openuigarage = false
            SetNuiFocus(false,false)
            SendNUIMessage({action = 'closeui'})
            CurrentPoint = nil
            local data_id = removeDeposit(data.plate)
            if data_id then
                TriggerServerEvent(ResourceName..':removeDepositCar', data.plate,data_id)
            end
            SpawnVehicle(json.decode(tableData.vehicle),tableData.plate,damage)
            Wait(1000)
            sendDiscordLog({
                webhook = 'garage_spawn',
                action = 'garage_spawn',
                plate = tableData.plate,
                durability = math.floor(damage.engine or 0),
                fuel = math.floor((damage.fuel or 0) + 0.5)
            })
            dprint(("[garage] spawnvehicle (deposit-out) -> %s"):format(tableData.plate))
        end)

    elseif CurrentPoint == 'garage' then
        cb('success')
        runGarageSpawnProgress(data.plate, function()
            openuigarage = false
            SetNuiFocus(false,false)
            SendNUIMessage({action = 'closeui'})
            SpawnVehicle(json.decode(tableData.vehicle),tableData.plate,damage)
            dprint(("[garage] spawnvehicle (garage-out) -> %s"):format(tableData.plate))
            Wait(1000)
            sendDiscordLog({
                webhook = 'garage_spawn',
                action = 'garage_spawn',
                plate = tableData.plate,
                durability = math.floor(damage.engine or 0),
                fuel = math.floor((damage.fuel or 0) + 0.5)
            })
        end)
    else
        cb('fail')
        delayCheck = false
        return
    end

    Wait(1500)
    CurrentPoint = nil
    delayCheck = false
end)

RegisterNUICallback('sendvehicle', function(data,cb)
    local tableData = getTableSpawn(data.plate)
    if tableData then
        if CurrentPoint =='pound' then
            local worldVehicle = findVehicleByPlate(data.plate)
            if worldVehicle and isAnyPlayerInVehicle(worldVehicle) then
                Config.notification('error', 'ไม่สามารถพาวน์ได้ เนื่องจากมีคนอยู่บนรถ')
                cb('fail')
                return
            end

            ESX.TriggerServerCallback(ResourceName..':payMoney', function(hasEnoughMoney)
                if hasEnoughMoney then
                    cb('success')
                    if checkOwner(tableData.plate,json.decode(tableData.vehicle).model) then
                        TriggerServerEvent(ResourceName..':deletePoundVehicle', tableData.plate)
                        TriggerServerEvent(ResourceName..':setStateVehicle', tableData.plate, true)
                        local data_id = removeDeposit(data.plate)
                        if data_id then  
                            TriggerServerEvent(ResourceName..':removeDepositCar', tableData.plate, data_id)
                        end
                        ReloadVehicleData(CurrentPoint,CurrentType)
                        dprint(("[garage] sendvehicle (pound->garage) -> %s"):format(tableData.plate))
                    end
                else 
                    cb('fail')
                end 
            end)
        else
            cb('fail')
        end 
    else 
        cb('fail')
    end 
end)

RegisterNUICallback('changeName', function(data,cb)
    for _ , v in pairs(Mystored) do 
        if samePlate(v.plate, data.plate) then
            if v.vehiclename ~= data.rename then
                Mystored[_].vehiclename = data.rename
            end 
        end 
    end 
    TriggerServerEvent(ResourceName..':renamevehicle',data.plate,data.rename)
    ReloadVehicleData(CurrentPoint,CurrentType)
    dprint(("[garage] changeName %s -> %s"):format(data.plate, data.rename))
end)

RegisterNUICallback('reloadVehicleData', function(data,cb)
    dprint('RELOAD VEHICLE DATA')
    ReloadVehicleData(CurrentPoint,CurrentType)
end)

RegisterNUICallback('exit', function(data,cb)
    closeGarageUi('nui_exit')
end)

function SetDamage(callback_vehicle, damage)
    dprint(ESX.DumpTable(damage))
	SetVehicleEngineHealth(callback_vehicle, damage.engine + 0.0 or 1000.0)
    if damage.health_body then
	    SetVehicleBodyHealth(callback_vehicle, damage.health_body + 0.0 or 1000.0)
    else
        SetVehicleBodyHealth(callback_vehicle, 1000.0)
    end
	if damage.tyres then
		for tyreId = 1, 7, 1 do
			if damage.tyres[tyreId] ~= false then
				SetVehicleTyreBurst(callback_vehicle, tyreId, true, 1000)
			end
		end
	end

	if damage.doors then
		for doorId = 0, 5, 1 do
			if damage.doors[doorId] ~= false then
				SetVehicleDoorBroken(callback_vehicle, doorId - 1, true)
			end
		end
	end
end

function SaveDamage(vehicle, vehicleProps)
	local damage = {}
	damage.tyres = {}
	damage.doors = {}

	for id = 1, 7 do
		local tyreId = IsVehicleTyreBurst(vehicle, id, false)
		if tyreId then
			damage.tyres[#damage.tyres + 1] = tyreId
			if tyreId == false then
				tyreId = IsVehicleTyreBurst(vehicle, id, true)
				damage.tyres[ #damage.tyres] = tyreId
			end
		else
			damage.tyres[#damage.tyres + 1] = false
		end
	end
	
	for id = 0, 5 do
		local doorId = IsVehicleDoorDamaged(vehicle, id)
		if doorId then
			damage.doors[#damage.doors + 1] = doorId
		else
			damage.doors[#damage.doors + 1] = false
		end
	end
	
	damage.fuel = GetVehicleFuelLevel(vehicle)
	damage.engine = GetVehicleEngineHealth(vehicle)
	damage.health_body = GetVehicleBodyHealth(vehicle)
    for _ , v in pairs(Mystored) do 
        local vehiclemodel = json.decode(v.vehicle).model 
        if samePlate(v.plate, vehicleProps.plate) and (vehiclemodel == vehicleProps.model or GetDisplayNameFromVehicleModel(vehicleProps.model):lower() == vehiclemodel) then
            v.health_vehicles = json.encode(damage)
            v.vehicle = json.encode(vehicleProps)
            TriggerServerEvent(ResourceName..'::modifyDamage', vehicleProps.plate, damage)
            dprint(("[garage] SaveDamage -> %s eng=%.1f body=%.1f fuel=%.1f"):format(
                vehicleProps.plate, damage.engine or -1, damage.health_body or -1, damage.fuel or -1
            ))
        end 
    end 
end

function trim(s)
    return s:match("^%s*(.-)%s*$")
end

exports('ModifyVehicle',function(plate,data) 
    for _ , v in pairs(Mystored) do
        if trim(tostring(v.plate)) == trim(tostring(plate)) then
            v.vehicle = json.encode(data)
        end
    end 
    dprint(("[garage] ModifyVehicle cache -> %s"):format(tostring(plate)))
end)

SetDataModify = function(plate,data) 
    for _ , v in pairs(Mystored) do 
        if v.plate == plate  then
            dprint("SAVE DATA "..tostring(plate))
            v.vehicle = data
        end 
    end 
end

function SpawnVehicleLast(model, plate)
    lastPlate = plate
    lastModel = model  
end
exports("SpawnVehicleLast", SpawnVehicleLast)

function CheckVehicle()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    if vehicle ~= 0 then
        local plate = GetVehicleNumberPlateText(vehicle)
        local model = GetEntityModel(vehicle) 
        if plate == lastPlate and lastModel ~= model then       
            return true, plate
        end
    end
    return false
end
exports("CheckVehicle", CheckVehicle)

GetCarTypeToNuiImage = function(veh)
	local visualCfg = getVehicleImageConfig(veh)
	if visualCfg and visualCfg.image then
		return visualCfg.image
	end

	local vc = GetVehicleClassFromName(veh)
	if vc == 8 then
		return 'moto'
    elseif vc == 4 then
		return 'muscle'
    elseif vc == 5 then
		return 'sports'
    elseif vc == 6 then
		return 'sports'
    elseif vc == 7 then
		return 'super'
    elseif vc == 9 then
		return 'off-road'
	elseif vc == 14 then
		return 'boat'
	elseif vc == 16 then
		return 'planes'
	elseif vc == 15 then
		return 'hali'
	else
		return 'cars'
	end
end
