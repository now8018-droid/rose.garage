local ResourceName = GetCurrentResourceName()


local serverEventThrottle = {}
local function triggerServerEventLimited(eventName, throttleKey, intervalMs, ...)
    local now = GetGameTimer()
    local key = tostring(throttleKey or eventName)
    local interval = tonumber(intervalMs) or 500

    local last = serverEventThrottle[key]
    if last and (now - last) < interval then
        return false
    end

    serverEventThrottle[key] = now
    TriggerServerEvent(eventName, ...)
    return true
end

local ESX = exports['es_extended']:getSharedObject()

Config = Config or {}
Config.DimensionsAllow = Config.DimensionsAllow or {0}
Config.garageDetail = Config.garageDetail or {}
Config.poundDetail = Config.poundDetail or {}
Config.depositvehicle = Config.depositvehicle or {}

local allowedDimensions = Config.DimensionsAllow -- มิติที่ต้องการเช็ค
local function getCurrentDimension()
    local ok, dim = pcall(function()
        return exports['val-setdimention']:GetDimension()
    end)
    if ok and dim ~= nil then return dim end

    ok, dim = pcall(function()
        return exports['val-setdimention']:GetCurrentDimension()
    end)
    if ok and dim ~= nil then return dim end

    return 0
end

local function getWhitelistDimensions()
    local ok, list = pcall(function()
        return exports['val-setdimention']:GetWhitelistDimen()
    end)
    if ok and type(list) == 'table' then return list end
    return {}
end

local cachedDimension = 0
local cachedWhitelistDimensions = {}

CreateThread(function()
    while true do
        cachedDimension = getCurrentDimension()
        cachedWhitelistDimensions = getWhitelistDimensions()
        Wait(500)
    end
end)

local function getCachedDimension()
    return cachedDimension
end

local function getCachedWhitelistDimensions()
    return cachedWhitelistDimensions
end

local function waitForFirstLoad(timeoutMs)
    if fistLoad then
        return true
    end

    local timeout = tonumber(timeoutMs) or 4000
    local deadline = GetGameTimer() + timeout

    while (not fistLoad) and GetGameTimer() < deadline do
        Wait(100)
    end

    return fistLoad
end


local function distSq(a, b)
    if not a or not b then return math.huge end
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = a.z - b.z
    return (dx * dx) + (dy * dy) + (dz * dz)
end

local locationIndex = {}
local locationPropspawn = {}
for id = 1, #Config.garageDetail do
    if Config.garageDetail[id].location then
        locationIndex[id] = Config.garageDetail[id].location
        locationPropspawn[id] = Config.garageDetail[id].Propspawn
    else
        locationIndex[id] = false
    end
    -- print(ESX.DumpTable(locationIndex))
end

local poundDetailIndex = {}
local poundPropspawn = {}
for id = 1, #Config.poundDetail do
    if Config.poundDetail[id].location then
        poundDetailIndex[id] = Config.poundDetail[id].location
        poundPropspawn[id] = Config.poundDetail[id].Propspawn
    else
        poundDetailIndex[id] = false
    end
end

local deletelocationDetailIndex = {}
local deletelocationPropspawn = {}
for id = 1, #Config.garageDetail do
    if Config.garageDetail[id].deletelocation then
        deletelocationDetailIndex[id] = Config.garageDetail[id].deletelocation
        deletelocationPropspawn[id] = Config.garageDetail[id].Propdelete
    else
        deletelocationDetailIndex[id] = false
    end
end

local DepositlocationDetailIndex = {}
for id = 1, #Config.depositvehicle do
    if Config.depositvehicle[id].location then
        DepositlocationDetailIndex[id] = Config.depositvehicle[id].location
    else
        DepositlocationDetailIndex[id] = false
    end
end

local garageSystemWakeRadius = Config.SystemWakeRadius or 80.0
local garageSystemWakeRadiusSq = garageSystemWakeRadius * garageSystemWakeRadius
local garageSystemWakeSleep = Config.SystemWakeSleep or 1200
local garageSystemWakeScanInterval = Config.SystemWakeScanInterval or 1000
local isGarageSystemAwake = false

local function isCoordsNearAnyGarageZone(coords)
    if not coords then return false end

    local function isNear(point)
        if not point then return false end
        local dx = coords.x - point.x
        local dy = coords.y - point.y
        local dz = coords.z - point.z
        return (dx * dx + dy * dy + dz * dz) <= garageSystemWakeRadiusSq
    end

    for i = 1, #locationIndex do
        if isNear(locationIndex[i]) or isNear(deletelocationDetailIndex[i]) then
            return true
        end
    end

    for i = 1, #poundDetailIndex do
        if isNear(poundDetailIndex[i]) then
            return true
        end
    end

    for i = 1, #DepositlocationDetailIndex do
        if isNear(DepositlocationDetailIndex[i]) then
            return true
        end
    end

    return false
end

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)

        isGarageSystemAwake = isCoordsNearAnyGarageZone(coords)
        if not isGarageSystemAwake then
            hasEnteredGarageMarker = false
            hasEnteredPoundMarker = false
            hasEnteredDeleteMarker = false
            hasEnteredDepositMarker = false
            lastGarageMarker = nil
            lastPoundMarker = nil
            lastDeleteMarker = nil
            lastDepositMarker = nil
        end

        Wait(garageSystemWakeScanInterval)
    end
end)

-- หา deposit ที่ใกล้สุดจาก coords แล้วอัปเดต active ตาม bool
function SetActiveDepositVehicle(coords, bool)
    if not coords then
        dprint("[Deposit] ❌ coords เป็น nil")
        return nil
    end

    local nearestIdx, nearestDist = nil, math.huge -- squared distance
    for i, data in ipairs(Config.depositvehicle or {}) do
        local loc = data.location
        if loc then
            local dist2 = distSq(coords, loc)
            if dist2 < nearestDist then
                nearestDist = dist2
                nearestIdx  = i
            end
        end
    end

    if not nearestIdx then
        dprint("[Deposit] ❌ ไม่พบจุดฝากใน Config.depositvehicle")
        return nil
    end

    local label = Config.depositvehicle[nearestIdx].Label or ("Deposit_"..nearestIdx)
    local old   = Config.depositvehicle[nearestIdx].active
    Config.depositvehicle[nearestIdx].active = not not bool

    dprint(("[Deposit] %s (idx=%d) → active %s -> %s (dist=%.2fm)")
        :format(label, nearestIdx, tostring(old), tostring(Config.depositvehicle[nearestIdx].active), math.sqrt(nearestDist)))

    return nearestIdx, label, Config.depositvehicle[nearestIdx].active, math.sqrt(nearestDist)
end
exports("SetActiveDepositVehicle", SetActiveDepositVehicle)

-- หา "deposit garage" ใกล้ที่สุด + นับจำนวนรถที่ฝากไว้ในจุดนั้น (อิง Mystored.v.deposit)
function GetNearestDepositInfo(coords)
    local nearestIdx, nearestLabel, nearestDist = nil, nil, 1e9 -- squared distance

    for i, data in ipairs(Config.depositvehicle) do
        if data.location then
            local dist2 = distSq(coords, data.location)
            if dist2 < nearestDist then
                nearestDist  = dist2
                nearestIdx   = i
                nearestLabel = data.Label or ("Deposit_"..i)
            end
        end
    end

    if not nearestIdx then
        dprint("[Garage] ไม่พบ deposit vehicle ใน Config.depositvehicle")
        return nil, nil, nil, 0, {}
    end

    local count, plates = 0, {}
    if Mystored then
        for _, v in pairs(Mystored) do
            if v.deposit ~= nil and v.deposit == nearestIdx then
                -- ทำความสะอาด state ที่ฝากค้าง (ตามโค้ดเดิมของคุณ)
                local data_id = removeDeposit(v.plate)
                if data_id then
                    triggerServerEventLimited(ResourceName..':removeDepositCar', 'removeDeposit:'..tostring(v.plate)..':'..tostring(data_id), Config.RemoveDepositEventCooldown or 5000, v.plate, data_id)
                end
                -- ถ้าต้องการนับจริง ให้ปลดคอมเมนต์สองบรรทัดนี้:
                -- count = count + 1
                -- plates[#plates+1] = v.plate
            end
        end
    end

    if count > 0 then
        dprint(("[Garage] Deposit ใกล้สุด: %s (%.2fm) มีรถฝากอยู่ %d คัน")
            :format(nearestLabel, math.sqrt(nearestDist), count))
    else
        dprint(("[Garage] Deposit ใกล้สุด: %s (%.2fm) ❌ ไม่มีรถฝาก")
            :format(nearestLabel, math.sqrt(nearestDist)))
    end

    return nearestIdx, nearestLabel, math.sqrt(nearestDist), count, plates
end
exports("GetNearestDepositInfo", GetNearestDepositInfo)

-- AddEventHandler("myResource:enteredMarker", function(markerType, markerID)
--     TriggerEvent("mythic_notify:client:SendAlert", {
--         text = "Entered " .. markerType .. " Marker ID: " .. markerID,
--         type = "inform",
--         timeout = 3000,
--     })
-- end)

-- AddEventHandler("myResource:exitedMarker", function(markerType, markerID)
--     TriggerEvent("mythic_notify:client:SendAlert", {
--         text = "Exited " .. markerType .. " Marker ID: " .. markerID,
--         type = "error",
--         timeout = 3000,
--     })
-- end)

function GetClosestMarker(playerCoords, markerIndex)
    local closestMarker = nil
    local minDistance = nil

    for id = 1, #markerIndex do
        if markerIndex[id] then
            local distance = distSq(playerCoords, markerIndex[id])
            if not minDistance or distance < minDistance then
                minDistance = distance
                closestMarker = id
            end
        end
    end
    return closestMarker, (minDistance and math.sqrt(minDistance) or nil)
end

hasEnteredGarageMarker = false
hasEnteredPoundMarker = false
hasEnteredDeleteMarker = false
hasEnteredDepositMarker = false
lastGarageMarker = nil
lastPoundMarker = nil
lastDeleteMarker = nil
lastDepositMarker = nil
markerRadius = 30.0

-- โปร่งใสเฉพาะรถในโซน Deposit (cfg.distDelete + 5.0)
local lastVeh = 0
local inGhostZone = false
local ghostOwned = false -- เราเป็นคนเปิด ghost อยู่ไหม
local lastNoCollisionScanAt = 0

local function applyNoCollisionWithNearbyVehicles(ent)
    if ent == 0 or not DoesEntityExist(ent) then return end

    local now = GetGameTimer()
    local scanInterval = Config.GhostNoCollisionScanInterval or 250
    if (now - lastNoCollisionScanAt) < scanInterval then
        return
    end
    lastNoCollisionScanAt = now

    local radius = Config.GhostNoCollisionRadius or Config.GhostRadius or 7.5
    local radius2 = radius * radius
    local maxProcess = Config.GhostNoCollisionMaxVehicles or 30
    local myCoords = GetEntityCoords(ent)
    local vehicles = GetGamePool('CVehicle')
    local processed = 0

    for i = 1, #vehicles do
        local other = vehicles[i]
        if other ~= ent and DoesEntityExist(other) then
            local o = GetEntityCoords(other)
            local dist2 = Vdist2(myCoords.x, myCoords.y, myCoords.z, o.x, o.y, o.z)
            if dist2 <= radius2 then
                SetEntityNoCollisionEntity(ent, other, true)
                SetEntityNoCollisionEntity(other, ent, true)
                processed = processed + 1
                if processed >= maxProcess then
                    break
                end
            end
        end
    end
end

local function setAlphaSafe(ent, alpha)
    if ent ~= 0 and DoesEntityExist(ent) then
        if GetEntityAlpha(ent) ~= alpha then
            SetEntityAlpha(ent, alpha, false)
        end
        -- กันรถชนกันเฉพาะกับรถรอบข้าง โดยไม่ปิด world collision (กันรถตกแมพ)
        applyNoCollisionWithNearbyVehicles(ent)
    end
    -- เปิด ghost ถ้ายังไม่ได้เปิดโดยเราเอง
    if not ghostOwned then
        SetLocalPlayerAsGhost(true)
        ghostOwned = true
    end
end

local function clearGhostAndAlpha(ent)
    -- รีเซ็ตความโปร่งใสของรถ (ถ้ารถยังอยู่)
    if ent ~= 0 and DoesEntityExist(ent) then
        if GetEntityAlpha(ent) ~= 255 then
            ResetEntityAlpha(ent)
        end
    end

    -- ปลด ghost ที่เราตั้ง
    if ghostOwned then
        SetLocalPlayerAsGhost(false)
        ghostOwned = false
    end
end

local function isInSpawnGhostRange(coords)
    local ghostCheckRadius = Config.GhostCheckRadius or Config.GhostRadius
    local defaultRadius = ghostCheckRadius or (Config.SpawnMarker and Config.SpawnMarker.x) or 5.0

    for _, cfg in ipairs(Config.garageDetail or {}) do
        if cfg.spawnlocation then
            local radius = (ghostCheckRadius and ghostCheckRadius > 0 and ghostCheckRadius) or cfg.GhostRadius or cfg.Radius or defaultRadius
            local radiusSq = radius * radius
            if distSq(coords, cfg.spawnlocation) <= radiusSq then
                return true
            end
        end
    end

    for _, cfg in ipairs(Config.poundDetail or {}) do
        if cfg.spawnlocation then
            local radius = (ghostCheckRadius and ghostCheckRadius > 0 and ghostCheckRadius) or cfg.GhostRadius or cfg.Radius or defaultRadius
            local radiusSq = radius * radius
            if distSq(coords, cfg.spawnlocation) <= radiusSq then
                return true
            end
        end
    end

    for _, cfg in ipairs(Config.depositvehicle or {}) do
        if cfg.spawnlocation then
            local radius = (ghostCheckRadius and ghostCheckRadius > 0 and ghostCheckRadius) or cfg.GhostRadius or cfg.distDelete or defaultRadius
            local radiusSq = radius * radius
            if distSq(coords, cfg.spawnlocation) <= radiusSq then
                return true
            end
        end
    end

    return false
end

local warnedMissingEsxCoreCircle = false

-- helper เอาไว้เรียก export ให้ถูกจำนวนพารามิเตอร์
local function DrawGarageCircle(center, radius, colorMarker, colorLine)
    local useEsxCoreCircle = GetResourceState('esx_core') == 'started'

    if useEsxCoreCircle then
        -- print("DrawGarageCircle", center, radius, colorMarker, colorLine)
        if colorMarker ~= nil and colorLine ~= nil then
            -- กรณีมีสีครบ ส่ง 4 ตัว
            exports['esx_core']:drawArenaCircleOnce(center, radius, colorMarker, colorLine)
        else
            -- กรณีไม่กำหนดสี ปล่อยให้ esx_core ใช้สี default
            exports['esx_core']:drawArenaCircleOnce(center, radius)
        end
        return true
    end

    if not warnedMissingEsxCoreCircle then
        warnedMissingEsxCoreCircle = true
        dprint('[Garage] esx_core ไม่ได้ทำงาน ใช้ DrawMarker วาดวง fallback แทน')
    end

    local markerColor = colorMarker or {r = 0, g = 255, b = 0, a = 80}
    DrawMarker(
        1,
        center.x, center.y, center.z,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        radius * 2.0, radius * 2.0, 0.12,
        markerColor.r, markerColor.g, markerColor.b, math.min(markerColor.a, 75),
        false, true, 2, false, nil, nil, false
    )
    return false
end

-- วาดเฉพาะ marker ใกล้สุดเพื่อลดวงซ้อนและลดโหลด
Citizen.CreateThread(function()
    local garageColorMarker = {r = 0, g = 255, b = 0, a = 100}
    local garageColorLine   = {r = 0, g = 255, b = 0, a = 255}

    local markerDrawDistance = Config.MarkerDrawDistance or 10.0

    while true do
        local sleep = Config.MarkerDrawLoopSleepFar or 900

        if isGarageSystemAwake then
            local ped    = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local inVeh  = IsPedInAnyVehicle(ped, false)

        local hasAnyMarker =
            (lastGarageMarker ~= nil and not locationPropspawn[lastGarageMarker]) or
            (lastDeleteMarker ~= nil) or
            (lastPoundMarker  ~= nil and not poundPropspawn[lastPoundMarker])

        if hasAnyMarker then
            local hasRenderableNear = false

            if (not inVeh) and lastGarageMarker then
                local loc = locationIndex[lastGarageMarker]
                if loc and #(coords - loc) <= (markerDrawDistance + 1.5) then
                    hasRenderableNear = true
                end
            end

            if inVeh and lastDeleteMarker then
                local loc = deletelocationDetailIndex[lastDeleteMarker]
                if loc and #(coords - loc) <= (markerDrawDistance + 1.5) then
                    hasRenderableNear = true
                end
            end

            if (not inVeh) and lastPoundMarker then
                local loc = poundDetailIndex[lastPoundMarker]
                if loc and #(coords - loc) <= (markerDrawDistance + 1.5) then
                    hasRenderableNear = true
                end
            end

            if hasRenderableNear then
                sleep = Config.MarkerDrawLoopSleepNear or 0
            else
                sleep = math.min(Config.MarkerDrawLoopSleepFar or 900, 450)
            end

            if (not inVeh) and lastGarageMarker then
                local id = lastGarageMarker
                local location = locationIndex[id]
                if location and not locationPropspawn[id] then
                    local inout, dis = distance(coords, location, markerDrawDistance)
                    if inout then
                        local cfg = Config.garageDetail[id]
                        local radius = (cfg and cfg.Radius) or 2.0
                        local vehicletype = cfg.vehicletype or 'car'
                        local markerType = Config.MarkerType[vehicletype] or 36
                        DrawGarageCircle(location - vec3(0, 0, 0.5), radius, garageColorMarker, garageColorLine)

                        if dis <= radius then
                            DrawMarker(
                                markerType,
                                location.x, location.y, location.z,
                                0.0, 0.0, 0.0,
                                0.0, 0.0, 0.0,
                                1.0, 1.0, 1.0,
                                garageColorMarker.r, garageColorMarker.g, garageColorMarker.b,
                                garageColorMarker.a * 3,
                                true, true, 2, false, nil, nil, false
                            )
                        end
                    end
                end
            end

            if inVeh and lastDeleteMarker then
                local id = lastDeleteMarker
                local location = deletelocationDetailIndex[id]
                if location then
                    local inout, dis = distance(coords, location, markerDrawDistance)
                    if inout then
                        local cfg = Config.garageDetail[id]
                        local radius = (cfg and cfg.DelRadius) or Config.DeleteMarker.x or 2.0
                        local markerType = Config.DeleteMarker.type or 6
                        local colorMarker = {r = Config.DeleteMarker.r, g = Config.DeleteMarker.g, b = Config.DeleteMarker.b, a = 100}
                        local colorLine   = {r = Config.DeleteMarker.r, g = Config.DeleteMarker.g, b = Config.DeleteMarker.b, a = 255}

                        local drewEsxCircle = DrawGarageCircle(location - vec3(0, 0, 0.5), radius, colorMarker, colorLine)
                        if drewEsxCircle and dis <= radius then
                            DrawMarker(
                                markerType,
                                location.x, location.y, location.z,
                                0.0, 0.0, 0.0,
                                0.0, 0.0, 0.0,
                                radius, radius, Config.DeleteMarker.z or 0.30,
                                255, 51, 51,
                                math.min((Config.DeleteMarker.a or 100) * 2, 255),
                                false, true, 2, false, nil, nil, false
                            )
                        end
                    end
                end
            end

            if (not inVeh) and lastPoundMarker then
                local id = lastPoundMarker
                local location = poundDetailIndex[id]
                if location and not poundPropspawn[id] then
                    local inout, dis = distance(coords, location, markerDrawDistance)
                    if inout then
                        local cfg = Config.poundDetail[id]
                        local radius = (cfg and cfg.Radius) or 1.5
                        local vehicletype = cfg.vehicletype or 'car'
                        local markerType = Config.MarkerType[vehicletype] or 36
                        local colorMarker = {r = Config.PoundMarker.r, g = Config.PoundMarker.g, b = Config.PoundMarker.b, a = 100}
                        local colorLine   = {r = Config.PoundMarker.r, g = Config.PoundMarker.g, b = Config.PoundMarker.b, a = 255}

                        DrawGarageCircle(location - vec3(0, 0, 0.5), radius, colorMarker, colorLine)
                        if dis <= radius then
                            DrawMarker(
                                markerType,
                                location.x, location.y, location.z,
                                0.0, 0.0, 0.0,
                                0.0, 0.0, 0.0,
                                1.0, 1.0, 1.0,
                                colorMarker.r, colorMarker.g, colorMarker.b,
                                colorMarker.a * 3,
                                true, true, 2, false, nil, nil, false
                            )
                        end
                    end
                end
            end
        end

        else
            sleep = math.max(garageSystemWakeSleep, sleep)
        end
        Citizen.Wait(sleep)
    end
end)

-- Citizen.CreateThread(function()
--     -- สีใช้ซ้ำ
--     local garageColorMarker = {r = 0, g = 255, b = 0, a = 100}
--     local garageColorLine   = {r = 0, g = 255, b = 0, a = 255}

--     while true do
--         local sleep = 1500

--         local ped    = PlayerPedId()
--         local coords = GetEntityCoords(ped)
--         local inVeh  = (GetVehiclePedIsUsing(ped) == 0)
--         -- local hasAnyMarker =
--         --     (lastDepositMarker ~= nil) or
--         --     (lastDeleteMarker  ~= nil) or
--         --     (lastPoundMarker   ~= nil) or
--         --     (lastGarageMarker  ~= nil)
--                 -- ✅ ปลุกเฉพาะตอน marker ที่เข้าใกล้ “มี propspawn”
--         local hasAnyMarker =
--                 (lastGarageMarker ~= nil and not locationPropspawn[lastGarageMarker]) or
--                 (lastDeleteMarker ~= nil and not deletelocationPropspawn[lastDeleteMarker]) or
--                 (lastPoundMarker  ~= nil and not poundPropspawn[lastPoundMarker])
--                 print("hasAnyMarker:", hasAnyMarker)
--         if hasAnyMarker then
--             sleep = 0

--             -- ======================
--             -- GARAGE (โชว์เฉพาะที่ prop[id] = true)
--             -- ======================
--             if inVeh then
--                 for id, location in pairs(locationIndex) do
--                     -- ✅ เช็กว่า prop เปิดอยู่ไหม
--                     if location then
--                         local inout, dis = distance(coords, location, 10.0)
--                         if inout then
--                             -- local radius = 2.0
--                             local cfg    = Config.garageDetail[id]
--                             local radius = (cfg and cfg.Radius) or 2.0
--                             local vehicletype = cfg.vehicletype or 'car'
--                             DrawGarageCircle(location - vec3(0, 0, 0.5), radius, garageColorMarker, garageColorLine)
--                             if dis <= radius then
--                                 -- print(vehicletype)
--                                 -- print(Config.MarkerType)
--                                 -- print(ESX.DumpTable(Config.MarkerType[vehicletype]))
--                                 DrawMarker(
--                                     Config.MarkerType[vehicletype],
--                                     location.x, location.y, location.z,
--                                     0.0, 0.0, 0.0,
--                                     0.0, 0.0, 0.0,
--                                     1.0, 1.0, 1.0,
--                                     garageColorMarker.r, garageColorMarker.g, garageColorMarker.b,
--                                     garageColorMarker.a * 3,
--                                     true, true, 2, false, nil, nil, false
--                                 )
--                             end
--                         end
--                     end
--                 end
--             end

--             -- ======================
--             -- DELETE (โชว์เฉพาะที่ prop[id] = true)
--             -- ======================
--             if not inVeh then
--                 for id, location in pairs(deletelocationDetailIndex) do
--                     -- ✅ เช็กว่า prop เปิดอยู่ไหม
--                     if location then
--                         local inout, dis = distance(coords, location, 10.0)
--                         if inout then
--                             -- local radius = Config.DeleteMarker.x
--                             local cfg    = Config.garageDetail[id]
--                             local radius = (cfg and cfg.Radius) or 2.0
--                             local vehicletype = cfg.vehicletype or 'car'
--                             local colorMarker = {r = Config.DeleteMarker.r, g = Config.DeleteMarker.g, b = Config.DeleteMarker.b, a = 100}
--                             local colorLine   = {r = Config.DeleteMarker.r, g = Config.DeleteMarker.g, b = Config.DeleteMarker.b, a = 255}
--                             DrawGarageCircle(location - vec3(0, 0, 0.5), radius, colorMarker, colorLine)
--                             if dis <= 4.0 then
--                                 DrawMarker(
--                                     -- Config.SpawnMarker.type,
--                                     Config.MarkerType[vehicletype],

--                                     location.x, location.y, location.z,
--                                     0.0, 0.0, 0.0,
--                                     0.0, 0.0, 0.0,
--                                     1.0, 1.0, 1.0,
--                                     Config.DeleteMarker.r, Config.DeleteMarker.g, Config.DeleteMarker.b,
--                                     Config.DeleteMarker.a * 3,
--                                     true, true, 2, false, nil, nil, false
--                                 )
--                             end
--                         end
--                     end
--                 end
--             end

--             -- ======================
--             -- POUND (โชว์เฉพาะที่ prop[id] = true)
--             -- ======================
--             if inVeh then
--                 for id, location in pairs(poundDetailIndex) do
--                     -- ✅ เช็กว่า prop เปิดอยู่ไหม
--                     if location then
--                         local inout, dis = distance(coords, location, 10.0)
--                         if inout then
--                             -- local radius = 1.5
--                             local cfg    = Config.poundDetail[id]
--                             local radius = (cfg and cfg.Radius) or 1.5   -- 👈 ใช้ Radius จากจุด
--                             local vehicletype = cfg.vehicletype or 'car'
--                             local colorMarker = {r = Config.PoundMarker.r, g = Config.PoundMarker.g, b = Config.PoundMarker.b, a = 100}
--                             local colorLine   = {r = Config.PoundMarker.r, g = Config.PoundMarker.g, b = Config.PoundMarker.b, a = 255}
--                             DrawGarageCircle(location - vec3(0, 0, 0.5), radius, colorMarker, colorLine)
--                             if dis <= radius then
--                                 DrawMarker(
--                                     Config.MarkerType[vehicletype],

--                                     location.x, location.y, location.z,
--                                     0.0, 0.0, 0.0,
--                                     0.0, 0.0, 0.0,
--                                     1.0, 1.0, 1.0,
--                                     colorMarker.r, colorMarker.g, colorMarker.b,
--                                     colorMarker.a * 3,
--                                     true, true, 2, false, nil, nil, false
--                                 )
--                             end
--                         end
--                     end
--                 end
--             end
--         end

--         Citizen.Wait(sleep)
--     end
-- end)

local lastMarkerScanAt = 0
local lastMarkerScanCoords = nil

local function shouldRunMarkerScan(coords, forceInterval, moveThreshold)
    local now = GetGameTimer()
    if not lastMarkerScanCoords then
        lastMarkerScanCoords = coords
        lastMarkerScanAt = now
        return true
    end

    local movedEnough = #(coords - lastMarkerScanCoords) >= (moveThreshold or 3.5)
    local timedOut = (now - lastMarkerScanAt) >= (forceInterval or 1500)
    if movedEnough or timedOut then
        lastMarkerScanCoords = coords
        lastMarkerScanAt = now
        return true
    end

    return false
end

Citizen.CreateThread(function()
    while true do
        local loopSleep = garageSystemWakeSleep

        if isGarageSystemAwake then
            local ped = PlayerPedId()
            local playerCoords = GetEntityCoords(ped)
            local veh = GetVehiclePedIsIn(ped, false)

        local hasNearbyContext = hasEnteredGarageMarker or hasEnteredPoundMarker or hasEnteredDeleteMarker or hasEnteredDepositMarker or inGhostZone
        loopSleep = hasNearbyContext and (Config.GhostLoopSleepNear or 350) or (Config.GhostLoopSleepFar or 1200)

        -- ถ้า lastVeh หายไปจากโลก ให้เคลียร์ ghost ทันที ป้องกันหลอน
        if inGhostZone then
            if lastVeh ~= 0 and not DoesEntityExist(lastVeh) then
                -- รถโดนลบ/หาย -> reset state ทั้งหมดทันที
                clearGhostAndAlpha(lastVeh)
                lastVeh = 0
                inGhostZone = false
            end
        else
            -- ถ้าเราไม่ได้อยู่ในโซนแล้ว แต่ ghostOwned ยัง true (failsafe)
            if ghostOwned then
                clearGhostAndAlpha(lastVeh)
                lastVeh = 0
            end
        end

        local markerScanInterval = hasNearbyContext and (Config.MarkerScanIntervalNear or 500) or (Config.MarkerScanIntervalFar or 2200)
        local canScanMarkers = shouldRunMarkerScan(playerCoords, markerScanInterval, 4.0)

        if canScanMarkers then
            -- ====== garage ======
            local currentGarageMarker, garageDistance = GetClosestMarker(playerCoords, locationIndex)
            if currentGarageMarker and garageDistance < markerRadius then
                if not hasEnteredGarageMarker then
                    hasEnteredGarageMarker = true
                    lastGarageMarker = currentGarageMarker
                elseif lastGarageMarker ~= currentGarageMarker then
                    lastGarageMarker = currentGarageMarker
                end
            else
                if hasEnteredGarageMarker then
                    hasEnteredGarageMarker = false
                    lastGarageMarker = nil
                end
            end

            -- ====== pound ======
            local currentPoundMarker, poundDistance = GetClosestMarker(playerCoords, poundDetailIndex)
            if currentPoundMarker and poundDistance < markerRadius then
                if not hasEnteredPoundMarker then
                    hasEnteredPoundMarker = true
                    lastPoundMarker = currentPoundMarker
                elseif lastPoundMarker ~= currentPoundMarker then
                    lastPoundMarker = currentPoundMarker
                end
            else
                if hasEnteredPoundMarker then
                    hasEnteredPoundMarker = false
                    lastPoundMarker = nil
                end
            end

            -- ====== delete location ======
            local currentDeleteMarker, deleteDistance = GetClosestMarker(playerCoords, deletelocationDetailIndex)
            if currentDeleteMarker and deleteDistance < markerRadius then
                if not hasEnteredDeleteMarker then
                    hasEnteredDeleteMarker = true
                    lastDeleteMarker = currentDeleteMarker
                elseif lastDeleteMarker ~= currentDeleteMarker then
                    lastDeleteMarker = currentDeleteMarker
                end
            else
                if hasEnteredDeleteMarker then
                    hasEnteredDeleteMarker = false
                    lastDeleteMarker = nil
                end
            end

            -- ====== deposit marker tracking ======
            local depositTrackRadius = math.max(markerRadius, ((Config.DepositMarker1 and Config.DepositMarker1.x) or 2.0) + 10.0)
            local currentDepositMarker, depositDistance = GetClosestMarker(playerCoords, DepositlocationDetailIndex)
            if currentDepositMarker and depositDistance < depositTrackRadius then
                if not hasEnteredDepositMarker then
                    hasEnteredDepositMarker = true
                    lastDepositMarker = currentDepositMarker
                elseif lastDepositMarker ~= currentDepositMarker then
                    lastDepositMarker = currentDepositMarker
                end
            else
                if hasEnteredDepositMarker then
                    hasEnteredDepositMarker = false
                    lastDepositMarker = nil
                end
            end
        end

        -- ====== spawn zone ghost logic (กันรถเบิกรถซ้อนกัน) ======
        local mydimen = getCachedDimension()
        local hasTrackedVeh = (lastVeh ~= 0 and DoesEntityExist(lastVeh))
        local canRunGhostCheck = (veh ~= 0) or inGhostZone or hasTrackedVeh
        local inGhostRange = false
        if canRunGhostCheck and (not isStoryDimension(mydimen)) then
            inGhostRange = isInSpawnGhostRange(playerCoords)
        end
        local shouldGhost = inGhostRange and ((veh ~= 0) or hasTrackedVeh)
        if inGhostZone then
            loopSleep = math.min(loopSleep, Config.GhostLoopSleepActive or 120)
        end

        if shouldGhost and not inGhostZone then
            inGhostZone = true
            setAlphaSafe(veh, 150)
            lastVeh = veh
        end

        if inGhostZone and shouldGhost then
            if lastVeh ~= 0 and DoesEntityExist(lastVeh) then
                -- ต้องเรียกทุก tick เพราะ no-collision แบบ this frame
                applyNoCollisionWithNearbyVehicles(lastVeh)
            end

            if veh ~= 0 and veh ~= lastVeh then
                clearGhostAndAlpha(lastVeh)
                setAlphaSafe(veh, 150)
                lastVeh = veh
            end

            if veh == 0 and lastVeh ~= 0 and DoesEntityExist(lastVeh) then
                -- ลงจากรถในระยะ Ghost: ให้รถคันล่าสุดยังคงใส/ทะลุต่อจนกว่าจะออกนอกระยะ
                setAlphaSafe(lastVeh, 150)
            end
        end

        if inGhostZone and not shouldGhost then
            inGhostZone = false
            clearGhostAndAlpha(lastVeh)
            lastVeh = 0
        elseif (not inGhostZone) and ghostOwned then
            clearGhostAndAlpha(lastVeh)
            lastVeh = 0
        end

        else
            loopSleep = garageSystemWakeSleep
        end
        Citizen.Wait(loopSleep)
    end
end)

function distance(Pcoords, location, redius)
    local coords = Pcoords
    local radius = tonumber(redius) or 0.0
    local dist2 = distSq(coords, location)
    local radiusSq = radius * radius
    if dist2 <= radiusSq then
        return true, math.sqrt(dist2)
    end
    return false
end

function isInDimension(dim)
    for _, v in ipairs(allowedDimensions) do
        dprint("[DimCheck]", v, dim)
        if v == dim then
            return true
        end
    end
    return false
end

function hasJob(jobReq, myJob)
    if jobReq == nil then return true end                 -- ไม่กำหนด = ผ่าน
    if not myJob then return false end                    -- ไม่มีอาชีพ = ไม่ผ่าน
    if type(jobReq) == "string" then
        return myJob == jobReq
    elseif type(jobReq) == "table" then
        for _, allowed in ipairs(jobReq) do
            if myJob == allowed then
                return true
            end
        end
        return false
    else
        -- ชนิดอื่นไม่รองรับ (กันพลาด)
        return false
    end
end
local function isInteractPressed()
    return IsControlJustPressed(0, 38)
end

local garageTextUiState = {
    isOpen = false,
    requests = {},
    requestTimeoutMs = tonumber(Config.TextUIRequestTimeoutMs) or 1200
}

local function setGarageTextUIRequest(sourceKey, keyText, text)
    local source = tostring(sourceKey or 'default')
    if not text or text == '' then
        garageTextUiState.requests[source] = nil
        return
    end

    garageTextUiState.requests[source] = {
        key = tostring(keyText or 'E'),
        text = tostring(text),
        touchedAt = GetGameTimer()
    }
end

CreateThread(function()
    local currentKey = nil
    local currentText = nil

    while true do
        if openuigarage then
            garageTextUiState.requests.main = nil
            garageTextUiState.requests.deposit = nil

            if garageTextUiState.isOpen then
                exports["val-textui"]:close()
                garageTextUiState.isOpen = false
                currentKey = nil
                currentText = nil
            end

            Wait(120)
            goto CONTINUE
        end

        local now = GetGameTimer()
        for source, payload in pairs(garageTextUiState.requests) do
            if (not payload.touchedAt) or (now - payload.touchedAt) > garageTextUiState.requestTimeoutMs then
                garageTextUiState.requests[source] = nil
            end
        end

        local payload = garageTextUiState.requests.main
        if not payload then
            payload = garageTextUiState.requests.deposit
        end

        if payload then
            if (not garageTextUiState.isOpen) or payload.key ~= currentKey or payload.text ~= currentText then
                exports["val-textui"]:open({
                    key = payload.key,
                    text = payload.text
                })
                garageTextUiState.isOpen = true
                currentKey = payload.key
                currentText = payload.text
            end
            Wait(0)
        else
            if garageTextUiState.isOpen then
                exports["val-textui"]:close()
                garageTextUiState.isOpen = false
                currentKey = nil
                currentText = nil
            end
            Wait(120)
        end

        ::CONTINUE::
    end
end)



-- โหมดโปร่งใส/ghost ขณะอยู่ในระยะ UI (val-textui)
-- local isGhostActive = false
-- local ghostVeh = 0         -- รถคันที่กำลังถูกทำให้ใสอยู่

-- CreateThread(function()
--     while true do
--         Wait(200)
--         local ped = PlayerPedId()
--         local veh = GetVehiclePedIsIn(ped, false)

--         if showUIDisplaytext then
--             -- เปิดโหมด ghost หนึ่งครั้ง
--             if not isGhostActive {
--                 isGhostActive = true
--                 SetLocalPlayerAsGhost(true)     -- กันชนกับผู้เล่นอื่น
--             }

--             -- บังคับให้ตัวละครโปร่งใสตลอดช่วงที่ UI โชว์
--             if GetEntityAlpha(ped) ~= 150 then
--                 SetEntityAlpha(ped, 150, false)
--             end

--             -- ถ้าอยู่ในรถ ให้ทำรถใสด้วย และรองรับการ "ขึ้นรถทีหลัง/เปลี่ยนคัน"
--             if veh ~= 0 then
--                 if ghostVeh ~= 0 and ghostVeh ~= veh and DoesEntityExist(ghostVeh) then
--                     ResetEntityAlpha(ghostVeh)  -- รีเซ็ตคันเก่าทันทีเมื่อเปลี่ยนคัน
--                 end
--                 ghostVeh = veh
--                 if GetEntityAlpha(veh) ~= 150 then
--                     SetEntityAlpha(veh, 150, false)
--                 end
--             else
--                 -- ไม่ได้อยู่ในรถ ถ้ามีคันที่เคยทำใสอยู่ ให้รีเซ็ตกลับ
--                 if ghostVeh ~= 0 and DoesEntityExist(ghostVeh) then
--                     ResetEntityAlpha(ghostVeh)
--                 end
--                 ghostVeh = 0
--             end

--         else
--             -- ปิดโหมด ghost และรีเซ็ตทุกอย่างเมื่อ UI ไม่โชว์แล้ว
--             if isGhostActive then
--                 isGhostActive = false
--                 SetLocalPlayerAsGhost(false)
--                 if GetEntityAlpha(ped) ~= 255 then
--                     ResetEntityAlpha(ped)
--                 end
--                 if ghostVeh ~= 0 and DoesEntityExist(ghostVeh) then
--                     ResetEntityAlpha(ghostVeh)
--                 end
--                 ghostVeh = 0
--             end
--         end
--     end
-- end)

function SetAlphaandGhost(entity, alpha, isGhost)
    if GetEntityAlpha(entity) ~= alpha then
        SetEntityAlpha(entity, alpha, false)
    end
    SetLocalPlayerAsGhost(isGhost)
end

Citizen.CreateThread(function()
    Wait(500)
    while true do
        ::START::
        local sleep = 1000

        local pressE = false
        local text = ''

        if isGarageSystemAwake then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local mrcoords = nil
        -- ลบรถ (delete spot) เมื่อนั่งรถอยู่
        if IsPedInAnyVehicle(ped, true) and lastDeleteMarker then
            if Config.garageDetail[lastDeleteMarker].deletelocation then
                if Vdist(coords, Config.garageDetail[lastDeleteMarker].deletelocation) <= Config.SeeMarker * 1.5 then
                    sleep = 0
                    local myJob = (PlayerData and PlayerData.job and PlayerData.job.name) or nil
                    local reqJob = Config.garageDetail[lastDeleteMarker].job
                    local delradius = Config.garageDetail[lastDeleteMarker].DelRadius or Config.DeleteMarker.x
                    if Vdist(coords, Config.garageDetail[lastDeleteMarker].deletelocation) <= delradius and CurrentPoint == nil and isInDimension(getCachedDimension()) and not openuigarage then

                        if not hasJob(reqJob, myJob) then
                            goto END
                        end

                        local veh = GetVehiclePedIsIn(ped, false)
                        local isDriver = (GetPedInVehicleSeat(veh, -1) == ped)
                        if not isDriver then
                            -- ไม่ใช่คนขับ = ไม่โชว์ UI, ไม่ให้กดอะไร
                            goto END
                        end

                        pressE = true
                        mrcoords = vector3(
                            Config.garageDetail[lastDeleteMarker].deletelocation.x,
                            Config.garageDetail[lastDeleteMarker].deletelocation.y,
                            Config.garageDetail[lastDeleteMarker].deletelocation.z - 0.3
                        )
                        text = 'STORED VEHICLE'
                        setGarageTextUIRequest("main", "E", text)
                        if isInteractPressed() then
                            -- if GetPedInVehicleSeat(GetVehiclePedIsIn(ped), -1) == ped then
                                if not fistLoad then
                                    TriggerServerEvent(ResourceName..':reloadData')
                                    waitForFirstLoad(4000)
                                end
                                -- ผ่านแล้ว ไม่ต้องเช็กซ้ำ
                                CurrentPoint = 'stored'
                                CurrentType = Config.garageDetail[lastDeleteMarker].vehicletype
                                StoreOwnedVehicleMenu()
                                dprint("[UI] Store vehicle confirmed at delete spot")
                            -- end
                        end
                        goto END
                    end
                end
            end
        else
            -- เปิดเมนู Garage เมื่อเดินเท้า
            if not IsPedInAnyVehicle(ped, true) and lastGarageMarker then
                if Vdist(coords, Config.garageDetail[lastGarageMarker].location) <= Config.SeeMarker * 1.5 then
                    sleep = 0
                    local myJob = (PlayerData and PlayerData.job and PlayerData.job.name) or nil
                    local reqJob = Config.garageDetail[lastGarageMarker].job
                    local gcfg   = Config.garageDetail[lastGarageMarker]
                    local gpos   = gcfg.location
                    local gradius= gcfg.Radius or Config.SpawnMarker.x  -- 👈 ดึงจากจุด
                    if Vdist(coords, gpos) <= gradius and CurrentPoint == nil and isInDimension(getCachedDimension()) and not openuigarage then

                        if not hasJob(reqJob, myJob) then goto END end

                        pressE = true
                        mrcoords = vector3(
                            Config.garageDetail[lastGarageMarker].location.x,
                            Config.garageDetail[lastGarageMarker].location.y,
                            Config.garageDetail[lastGarageMarker].location.z - 0.25
                        )
                        -- print(Config.SpawnMarker.x)
                        text = 'OPEN GARAGE'
                        setGarageTextUIRequest("main", "E", text)
                        if isInteractPressed() then
                            if not fistLoad then
                                SetNuiFocus(true, true)
                                TriggerServerEvent(ResourceName..':reloadData')
                                waitForFirstLoad(4000)
                            end
                            CurrentPoint = 'garage'
                            CurrentType = Config.garageDetail[lastGarageMarker].vehicletype
                            this_GaragePoint = Config.garageDetail[lastGarageMarker].spawnlocation
                            this_GarageHeading = Config.garageDetail[lastGarageMarker].spawnheading
                            GarageUiAnchorPoint = gpos
                            GarageUiAutoCloseRadius = gradius + 2.0
                            -- (คงพฤติกรรมเดิม) ถ้ามีการล็อก job ให้ส่ง reqJob ไปด้วย
                            if reqJob ~= nil then
                                openGarage(CurrentPoint, CurrentType, reqJob)
                            else
                                openGarage(CurrentPoint, CurrentType)
                            end
                            dprint("[UI] Open Garage menu")
                        end
                    end
                end
            end
        end

        -- พื้นที่ Pound
        -- print('lastPoundMarker', lastPoundMarker) -- ตามต้องการ
        if IsPedInAnyVehicle(ped, true) and lastPoundMarker then
            goto END
        else
            if lastPoundMarker then
                while not PlayerData do
                    PlayerData = ESX.GetPlayerData()
                    Wait(0)
                end
                local poundConfig = Config.poundDetail[lastPoundMarker]
                local myJob = (PlayerData and PlayerData.job and PlayerData.job.name) or nil
                local reqJob = poundConfig.job -- อาจเป็น string หรือ table
                -- ใช้ hasJob: ถ้ามี reqJob ต้องผ่าน, ถ้าไม่มี reqJob เปิดได้ทุกอาชีพ (รวม unemployed)
                -- print(hasJob(reqJob, myJob))
                local pradius = poundConfig.Radius or Config.PoundMarker.x

                if hasJob(reqJob, myJob) then
                    if Vdist(coords, poundConfig.location) <= Config.SeeMarker * 1.5 then
                        sleep = 0
                        if Vdist(coords, poundConfig.location) <= pradius and CurrentPoint == nil and isInDimension(getCachedDimension()) and not openuigarage then
                            pressE = true
                            mrcoords = vector3(poundConfig.location.x, poundConfig.location.y, poundConfig.location.z - 0.3)
                            text = 'OPEN POUND VEHICLE MENU'
                            setGarageTextUIRequest("main", "E", text)
                            if isInteractPressed() then
                                if not fistLoad then
                                    SetNuiFocus(true, true)
                                    TriggerServerEvent(ResourceName..':reloadData')
                                    waitForFirstLoad(4000)
                                end
                                CurrentPoint = 'pound'
                                CurrentType = poundConfig.vehicletype
                                this_GaragePoint = poundConfig.spawnlocation
                                this_GarageHeading = poundConfig.spawnheading
                                GarageUiAnchorPoint = poundConfig.location
                                GarageUiAutoCloseRadius = pradius + 2.0
                                -- (คงพฤติกรรมเดิมของคุณ) ถ้าล็อก job อยู่ ให้ส่งชื่อ job ผู้เล่น
                                if reqJob then
                                    if myJob then
                                        openGarage(CurrentPoint, CurrentType, myJob)
                                    end
                                else
                                    openGarage(CurrentPoint, CurrentType)
                                end
                                dprint("[UI] Open Pound menu")
                            end
                            goto END
                        end
                    end
                end
            end
        end

        ::END::
        -- แสดง/ซ่อน UI ปุ่ม E (debug)
        if pressE then
            if not showUIDisplaytext then
                showUIDisplaytext = true
                -- print("[UI] show", text)
                dprint("[UI] show", text)
            end
        else
            if showUIDisplaytext then
                showUIDisplaytext = false
                -- print("[UI] hide", showUIDisplaytext)
                dprint("[UI] hide", showUIDisplaytext)
                Wait(200)
            end
            setGarageTextUIRequest("main", nil, nil)
        end
        else
            setGarageTextUIRequest("main", nil, nil)
            sleep = garageSystemWakeSleep
        end
        Citizen.Wait(sleep)
    end
end)

function OpenGarageNear(coords)
    local nearestIdx, nearestLabel, nearestDist = nil, nil, 1e9 -- squared distance

    for i, data in ipairs(Config.depositvehicle) do
        if data.location then
            local dist = distSq(coords, data.location)
            if dist < nearestDist then
                -- nearestDist  = dist
                -- nearestIdx   = i
                -- nearestLabel = data.Label or ("Deposit_"..i)
                if not fistLoad then
                    SetNuiFocus(true, true)
                    TriggerServerEvent(ResourceName..':reloadData')
                    waitForFirstLoad(4000)
                end
                local idx = lastDepositMarker
                local cfg = (idx and Config.depositvehicle[idx]) or nil
                CurrentPoint      = 'deposit'
                this_GaragePoint  = cfg.spawnlocation
                this_GarageHeading= cfg.spawnheading
                GarageUiAnchorPoint = cfg.location
                GarageUiAutoCloseRadius = ((Config.DepositMarker1 and Config.DepositMarker1.x) or 2.0) + 2.0
                openGarage(CurrentPoint, idx)
            end
        end
    end
end

exports("OpenGarageNear", OpenGarageNear)

function isStoryDimension(dim)
    local WhitelistDimen = getCachedWhitelistDimensions()
    for _, allowed in ipairs(WhitelistDimen) do
        if dim == allowed then
            return true
        end
    end
    return false
end

CreateThread(function()
    while true do
        local sleep = 1100

        if isGarageSystemAwake then
            local ped   = PlayerPedId()
            local coords= GetEntityCoords(ped)

        local idx = lastDepositMarker
        local cfg = (idx and Config.depositvehicle[idx]) or nil
        local depositUiActive = false
        if IsPedInAnyVehicle(ped, true) then
            if cfg and cfg.active then
                local dist = #(coords - cfg.deletelocation)
                local depositWorkRadius = math.max((cfg.distDelete or 2.0) + 15.0, ((Config.DepositMarker1 and Config.DepositMarker1.x) or 2.0) + 10.0)
                if dist <= depositWorkRadius then
                    sleep = 350
                    local inside = dist <= cfg.distDelete and (CurrentPoint == nil)
                    local veh = GetVehiclePedIsIn(ped, false)
                    local isDriver = (GetPedInVehicleSeat(veh, -1) == ped)
                    local mydimen = getCachedDimension()

                    if inside and isInDimension(getCachedDimension()) and not openuigarage and isDriver and not isStoryDimension(mydimen) then
                        sleep = 0
                        -- DrawMarker(
                        --     Config.DepositMarker2.type,
                        --     cfg.deletelocation.x, cfg.deletelocation.y, cfg.deletelocation.z,
                        --     0.0,0.0,0.0, 0,0.0,0.0,
                        --     cfg.distDelete, cfg.distDelete, cfg.distDelete,
                        --     Config.DepositMarker2.r, Config.DepositMarker2.g, Config.DepositMarker2.b,
                        --     90,false,false,2,false,false,false,false
                        -- )
                        if not cfg.autodelete then
                            setGarageTextUIRequest("deposit", "E", "ฝากรถ")
                            depositUiActive = true
                            if isInteractPressed() then
                                dprint("[Deposit] Success: hold E to deposit")
                                if not fistLoad then
                                    TriggerServerEvent(ResourceName..':reloadData')
                                    waitForFirstLoad(4000)
                                end
                                CurrentPoint = 'deposit'
                                this_GaragePoint = cfg.location
                                this_GarageHeading = cfg.spawnheading
                                StoreVehicle_deposit(idx)
                            end
                        else
                            if not isStoryDimension(mydimen) then
                                if not fistLoad then
                                    TriggerServerEvent(ResourceName..':reloadData')
                                    waitForFirstLoad(4000)
                                end
                                CurrentPoint = 'deposit'
                                this_GaragePoint = cfg.location
                                this_GarageHeading = cfg.spawnheading
                                StoreVehicle_deposit(idx)
                            end
                        end
                    end
                end
            end
        else
            -- เดินเท้า: จุดเปิดเมนูฝากรถ
            if idx then
                local dist = #(coords - cfg.location)
                if dist <= Config.DepositMarker1.x and not openuigarage then
                    sleep = 200
                    dprint("[DimCheck-foot]", isInDimension(getCachedDimension()))
                    if (CurrentPoint == nil) and isInDimension(getCachedDimension()) then
                        sleep = 0
                        setGarageTextUIRequest("deposit", "E", "เปิดเมนูฝากรถ")
                        depositUiActive = true
                        if isInteractPressed() then
                            if not fistLoad then
                                SetNuiFocus(true,true)
                                TriggerServerEvent(ResourceName..':reloadData')
                                waitForFirstLoad(4000)
                            end
                            CurrentPoint      = 'deposit'
                            this_GaragePoint  = cfg.spawnlocation
                            this_GarageHeading= cfg.spawnheading
                            GarageUiAnchorPoint = cfg.location
                            GarageUiAutoCloseRadius = ((Config.DepositMarker1 and Config.DepositMarker1.x) or 2.0) + 2.0
                            openGarage(CurrentPoint, idx)
                            dprint("[UI] Open Deposit menu")
                        end
                    end
                end
            end
        end
        if not depositUiActive then
            setGarageTextUIRequest("deposit", nil, nil)
        end
        else
            setGarageTextUIRequest("deposit", nil, nil)
            sleep = garageSystemWakeSleep
        end
        Wait(sleep)
    end
end)
