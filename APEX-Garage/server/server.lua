local ESX = exports['es_extended'] and exports['es_extended']:getSharedObject() or nil
local ResourceName = GetCurrentResourceName()

local performance = (Config and Config.Performance) or {}
local ReloadCacheMs = tonumber(performance.ReloadCacheMs) or 3000
local WriteFlushIntervalMs = tonumber(performance.WriteFlushIntervalMs) or 12000
local DamageFlushIntervalMs = tonumber(performance.DamageFlushIntervalMs) or 12000
local ReloadDispatchCooldownMs = tonumber(performance.ReloadDispatchCooldownMs) or 350
local PoundBroadcastCooldownMs = tonumber(performance.PoundBroadcastCooldownMs) or 1500
local EventRateLimitMs = tonumber(performance.EventRateLimitMs) or 350

-- Runtime systems (production-style caches/indexes)
local PLAYER_CACHE = {}     -- [src] = { identifier, name, job, ped, lastSeen }
local PLAYER_PEDS = {}      -- [src] = ped entity
local PLAYER_STATE = {}     -- [src] = { cooldowns = {}, flags = {} }
local JOB_INDEX = {}        -- [jobName] = { [src] = true }
local LOCK_SYSTEM = {}      -- [lockKey] = true
local WRITE_QUEUE = {}      -- queued db writes
local TASK_SCHEDULER = {}   -- interval task scheduler

local ownerVehicleCache = {}
local plateOwnerMap = {}
local pendingDamageUpdates = {}
local poundBroadcastCooldowns = {}
local reloadDispatchAt = {}

local function nowMs()
    return GetGameTimer()
end

CreateThread(function()
    if ESX then return end
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Wait(200)
    end
end)

local function normalizePlate(plate)
    return tostring(plate or ''):gsub('^%s*(.-)%s*$', '%1'):upper()
end

local function decodeJsonSafe(payload)
    if type(payload) ~= 'string' or payload == '' then return nil end
    local ok, decoded = pcall(json.decode, payload)
    if ok and type(decoded) == 'table' then
        return decoded
    end
    return nil
end

local function encodeJsonSafe(data)
    local ok, encoded = pcall(json.encode, data)
    if ok then return encoded end
    return nil
end

local function dbExecute(query, params)
    local ok, result = pcall(MySQL.update.await, query, params or {})
    if ok then return result end
    print(('[%s] dbExecute failed: %s'):format(ResourceName, tostring(result)))
    return nil
end

local function dbFetchAll(query, params)
    local ok, result = pcall(MySQL.query.await, query, params or {})
    if ok and type(result) == 'table' then return result end
    if not ok then
        print(('[%s] dbFetchAll failed: %s'):format(ResourceName, tostring(result)))
    end
    return {}
end

local function queueWrite(query, params)
    WRITE_QUEUE[#WRITE_QUEUE + 1] = { query = query, params = params or {} }
end

local function acquireLock(lockKey)
    if LOCK_SYSTEM[lockKey] then
        return false
    end
    LOCK_SYSTEM[lockKey] = true
    return true
end

local function releaseLock(lockKey)
    LOCK_SYSTEM[lockKey] = nil
end

local function invalidatePlateCache(plate)
    local normalized = normalizePlate(plate)
    if normalized == '' then return end
    local owner = plateOwnerMap[normalized]
    if owner then
        ownerVehicleCache[owner] = nil
    end
end

local function getPlayer(src)
    if not ESX then return nil end
    return ESX.GetPlayerFromId(src)
end

local function trackPlayer(src, xPlayer)
    if type(src) ~= 'number' or src <= 0 then return nil end
    if not xPlayer then
        xPlayer = getPlayer(src)
    end
    if not xPlayer then return nil end

    local identifier = xPlayer.getIdentifier and xPlayer.getIdentifier() or xPlayer.identifier
    local name = xPlayer.getName and xPlayer.getName() or GetPlayerName(src) or ('ID '..tostring(src))
    local jobName = xPlayer.job and xPlayer.job.name or 'unemployed'
    local ped = GetPlayerPed(src)

    local prev = PLAYER_CACHE[src]
    if prev and prev.job and JOB_INDEX[prev.job] then
        JOB_INDEX[prev.job][src] = nil
    end

    PLAYER_CACHE[src] = {
        identifier = identifier,
        name = name,
        job = jobName,
        ped = ped,
        lastSeen = nowMs()
    }
    PLAYER_PEDS[src] = ped

    JOB_INDEX[jobName] = JOB_INDEX[jobName] or {}
    JOB_INDEX[jobName][src] = true

    PLAYER_STATE[src] = PLAYER_STATE[src] or { cooldowns = {}, flags = {} }

    return PLAYER_CACHE[src]
end

local function removePlayerCache(src)
    local entry = PLAYER_CACHE[src]
    if entry and entry.job and JOB_INDEX[entry.job] then
        JOB_INDEX[entry.job][src] = nil
    end
    PLAYER_CACHE[src] = nil
    PLAYER_PEDS[src] = nil
    PLAYER_STATE[src] = nil
    reloadDispatchAt[src] = nil
end

local function enforceCooldown(src, key, intervalMs)
    PLAYER_STATE[src] = PLAYER_STATE[src] or { cooldowns = {}, flags = {} }
    local cooldowns = PLAYER_STATE[src].cooldowns
    local now = nowMs()
    local readyAt = cooldowns[key] or 0
    if now < readyAt then
        return false
    end
    cooldowns[key] = now + (tonumber(intervalMs) or EventRateLimitMs)
    return true
end

local function validateSource(src)
    return type(src) == 'number' and src > 0 and GetPlayerName(src) ~= nil
end

local function getPlayerCoords(src)
    local ped = PLAYER_PEDS[src]
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        ped = GetPlayerPed(src)
        PLAYER_PEDS[src] = ped
    end
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        return nil
    end
    return GetEntityCoords(ped)
end

local function isNearAnyConfiguredZone(src, radius)
    local coords = getPlayerCoords(src)
    if not coords then return false end
    local maxDist = tonumber(radius) or 150.0
    local maxDistSq = maxDist * maxDist

    local function checkList(list)
        for i = 1, #list do
            local row = list[i]
            if row and row.location then
                local dx = coords.x - row.location.x
                local dy = coords.y - row.location.y
                local dz = coords.z - row.location.z
                if (dx * dx + dy * dy + dz * dz) <= maxDistSq then
                    return true
                end
            end
            if row and row.deletelocation then
                local dx = coords.x - row.deletelocation.x
                local dy = coords.y - row.deletelocation.y
                local dz = coords.z - row.deletelocation.z
                if (dx * dx + dy * dy + dz * dz) <= maxDistSq then
                    return true
                end
            end
        end
        return false
    end

    return checkList(Config.garageDetail or {})
        or checkList(Config.poundDetail or {})
        or checkList(Config.depositvehicle or {})
end

local function ownsVehicle(identifier, plate)
    if not identifier or not plate then return false end
    local vehicles = ownerVehicleCache[identifier] and ownerVehicleCache[identifier].data
    if not vehicles then return false end
    local normalized = normalizePlate(plate)
    for i = 1, #vehicles do
        if normalizePlate(vehicles[i].plate) == normalized then
            return true
        end
    end
    return false
end

local function fetchVehicles(identifier)
    local now = nowMs()
    local cached = ownerVehicleCache[identifier]
    if cached and cached.expiresAt > now then
        return cached.data
    end

    local result = dbFetchAll('SELECT owner, plate, vehicle, type, stored, police, job, vehiclename, health_vehicles, deposit FROM owned_vehicles WHERE owner = ?', {
        identifier
    })

    local list, plateIndexMap, plates = {}, {}, {}
    for i = 1, #result do
        local r = result[i]
        local normalizedPlate = normalizePlate(r.plate)
        list[#list + 1] = {
            plate = r.plate,
            stored = r.stored == 1 or r.stored == true,
            police = r.police or 0,
            job = r.job or '',
            type = r.type or 'car',
            vehiclename = r.vehiclename,
            vehicle = r.vehicle,
            health_vehicles = r.health_vehicles,
            deposit = r.deposit
        }

        if normalizedPlate ~= '' and not plateIndexMap[normalizedPlate] then
            plateIndexMap[normalizedPlate] = #list
            plates[#plates + 1] = normalizedPlate
            plateOwnerMap[normalizedPlate] = identifier
        end
    end

    if #plates > 0 then
        local placeholders = table.concat((function()
            local t = {}
            for i = 1, #plates do t[i] = '?' end
            return t
        end)(), ',')

        local customRows = dbFetchAll(('SELECT plate, props FROM apex_custom_props WHERE plate IN (%s)'):format(placeholders), plates)
        for i = 1, #customRows do
            local row = customRows[i]
            local idx = plateIndexMap[normalizePlate(row.plate)]
            if idx and row.props then
                local decodedProps = decodeJsonSafe(row.props)
                local encodedProps = decodedProps and encodeJsonSafe(decodedProps) or nil
                if encodedProps then
                    list[idx].vehicle = encodedProps
                end
            end
        end
    end

    ownerVehicleCache[identifier] = { data = list, expiresAt = now + ReloadCacheMs }
    return list
end

local function flushPendingDamage()
    if not next(pendingDamageUpdates) then return end
    local batch = pendingDamageUpdates
    pendingDamageUpdates = {}

    for plate, encodedDamage in pairs(batch) do
        queueWrite('UPDATE owned_vehicles SET health_vehicles = ? WHERE plate = ?', {
            encodedDamage,
            plate
        })
        invalidatePlateCache(plate)
    end
end

local function flushWriteQueue()
    if #WRITE_QUEUE == 0 then return end

    local lockKey = 'write_queue_flush'
    if not acquireLock(lockKey) then return end

    local batch = WRITE_QUEUE
    WRITE_QUEUE = {}

    for i = 1, #batch do
        local item = batch[i]
        dbExecute(item.query, item.params)
    end

    releaseLock(lockKey)
end

local function registerTask(name, intervalMs, fn)
    TASK_SCHEDULER[#TASK_SCHEDULER + 1] = {
        name = name,
        interval = intervalMs,
        nextRun = nowMs() + intervalMs,
        handler = fn
    }
end

local function sendWebhook(url, title, description, color)
    if not url or url == '' then return end

    local body = {
        username = 'APEX-Garage',
        embeds = {
            { title = title, description = description, color = color or 16711680 }
        }
    }

    PerformHttpRequest(url, function() end, 'POST', json.encode(body), {
        ['Content-Type'] = 'application/json'
    })
end

RegisterNetEvent(ResourceName..':logWebhook', function(payload)
    local src = source
    if not validateSource(src) then return end
    if type(payload) ~= 'table' then return end
    if not enforceCooldown(src, 'logWebhook', 1000) then return end

    local tracked = trackPlayer(src)
    if not tracked then return end

    local action = tostring(payload.action or payload.webhook or '')
    local plate = tostring(payload.plate or '-')
    local durability = tonumber(payload.durability or 0) or 0
    local fuel = tonumber(payload.fuel or 0) or 0

    local titleMap = {
        storevehicle = 'เก็บรถ',
        garage_spawn = 'เบิกรถ',
        garage_pound = 'พาวน์รถ'
    }

    local title = titleMap[action] or 'Garage Log'
    local desc = ('ชื่อเจ้าของรถ: %s\nทะเบียน: %s\nความคงทนรถ: %.1f\nน้ำมัน: %.1f')
        :format(tracked.name or ('ID '..tostring(src)), plate, durability, fuel)

    local webhookUrl = Config.Webhooks and Config.Webhooks[action] or nil
    sendWebhook(webhookUrl, title, desc, 16711680)
end)

RegisterNetEvent(ResourceName..':reloadData', function()
    local src = source
    if not validateSource(src) then return end
    if not enforceCooldown(src, 'reloadData', ReloadDispatchCooldownMs) then return end

    local xPlayer = getPlayer(src)
    local tracked = trackPlayer(src, xPlayer)
    if not tracked or not tracked.identifier then return end

    if not isNearAnyConfiguredZone(src, 350.0) then
        return
    end

    local vehicles = fetchVehicles(tracked.identifier)
    TriggerClientEvent(ResourceName..':reloadData:client', src, vehicles)
end)

RegisterNetEvent(ResourceName..':setStateVehicle', function(plate, stored, props)
    local src = source
    if not validateSource(src) then return end
    if type(plate) ~= 'string' or plate == '' then return end
    if type(stored) ~= 'boolean' then return end
    if not enforceCooldown(src, 'setStateVehicle', EventRateLimitMs) then return end

    local xPlayer = getPlayer(src)
    local tracked = trackPlayer(src, xPlayer)
    if not tracked or not tracked.identifier then return end
    if not isNearAnyConfiguredZone(src, 150.0) then return end

    local normalizedPlate = normalizePlate(plate)
    if normalizedPlate == '' then return end

    fetchVehicles(tracked.identifier)
    if not ownsVehicle(tracked.identifier, normalizedPlate) then return end

    local s = stored and 1 or 0
    if type(props) == 'table' then
        props.plate = normalizedPlate
        local encodedProps = encodeJsonSafe(props)
        if encodedProps then
            queueWrite('UPDATE owned_vehicles SET stored = ?, vehicle = ? WHERE plate = ?', { s, encodedProps, normalizedPlate })
            queueWrite('REPLACE INTO apex_custom_props (plate, props) VALUES (?, ?)', { normalizedPlate, encodedProps })
            invalidatePlateCache(normalizedPlate)
            return
        end
    end

    queueWrite('UPDATE owned_vehicles SET stored = ? WHERE plate = ?', { s, normalizedPlate })
    invalidatePlateCache(normalizedPlate)
end)

RegisterNetEvent(ResourceName..':depositvehicles', function(plate, depositId)
    local src = source
    if not validateSource(src) then return end
    if type(plate) ~= 'string' or plate == '' then return end
    if not enforceCooldown(src, 'depositvehicles', EventRateLimitMs) then return end

    local xPlayer = getPlayer(src)
    local tracked = trackPlayer(src, xPlayer)
    if not tracked or not tracked.identifier then return end
    if not isNearAnyConfiguredZone(src, 120.0) then return end

    local normalizedPlate = normalizePlate(plate)
    fetchVehicles(tracked.identifier)
    if not ownsVehicle(tracked.identifier, normalizedPlate) then return end

    queueWrite('UPDATE owned_vehicles SET deposit = ? WHERE plate = ?', { tonumber(depositId), normalizedPlate })
    invalidatePlateCache(normalizedPlate)
end)

RegisterNetEvent(ResourceName..':removeDepositCar', function(plate)
    local src = source
    if not validateSource(src) then return end
    if type(plate) ~= 'string' or plate == '' then return end
    if not enforceCooldown(src, 'removeDepositCar', EventRateLimitMs) then return end

    local xPlayer = getPlayer(src)
    local tracked = trackPlayer(src, xPlayer)
    if not tracked or not tracked.identifier then return end

    local normalizedPlate = normalizePlate(plate)
    fetchVehicles(tracked.identifier)
    if not ownsVehicle(tracked.identifier, normalizedPlate) then return end

    queueWrite('UPDATE owned_vehicles SET deposit = NULL WHERE plate = ?', { normalizedPlate })
    invalidatePlateCache(normalizedPlate)
end)

RegisterNetEvent(ResourceName..':deletePoundVehicle', function(plate)
    local src = source
    if not validateSource(src) then return end
    if type(plate) ~= 'string' or plate == '' then return end
    if not enforceCooldown(src, 'deletePoundVehicle', PoundBroadcastCooldownMs) then return end

    local normalizedPlate = normalizePlate(plate)
    local now = nowMs()
    local nextAllowed = poundBroadcastCooldowns[normalizedPlate] or 0
    if now < nextAllowed then return end

    poundBroadcastCooldowns[normalizedPlate] = now + PoundBroadcastCooldownMs
    TriggerClientEvent(ResourceName..':deletePoundVehicleAll', -1, normalizedPlate)
end)

RegisterNetEvent(ResourceName..':openTrunk', function(_plate)
    local src = source
    if not validateSource(src) then return end
end)

RegisterNetEvent(ResourceName..':renamevehicle', function(plate, rename)
    local src = source
    if not validateSource(src) then return end
    if type(plate) ~= 'string' or plate == '' then return end
    if type(rename) ~= 'string' or rename == '' then return end
    if #rename > 64 then return end
    if not enforceCooldown(src, 'renamevehicle', 500) then return end

    local xPlayer = getPlayer(src)
    local tracked = trackPlayer(src, xPlayer)
    if not tracked or not tracked.identifier then return end

    local normalizedPlate = normalizePlate(plate)
    fetchVehicles(tracked.identifier)
    if not ownsVehicle(tracked.identifier, normalizedPlate) then return end

    queueWrite('UPDATE owned_vehicles SET vehiclename = ? WHERE plate = ?', { rename, normalizedPlate })
    invalidatePlateCache(normalizedPlate)
end)

RegisterNetEvent(ResourceName..'::modifyDamage', function(plate, damage)
    local src = source
    if not validateSource(src) then return end
    if type(plate) ~= 'string' or plate == '' then return end
    if type(damage) ~= 'table' then return end
    if not enforceCooldown(src, 'modifyDamage', 500) then return end

    local xPlayer = getPlayer(src)
    local tracked = trackPlayer(src, xPlayer)
    if not tracked or not tracked.identifier then return end

    local encodedDamage = encodeJsonSafe(damage)
    if not encodedDamage then return end

    local normalizedPlate = normalizePlate(plate)
    fetchVehicles(tracked.identifier)
    if not ownsVehicle(tracked.identifier, normalizedPlate) then return end

    pendingDamageUpdates[normalizedPlate] = encodedDamage
end)

AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
    trackPlayer(playerId, xPlayer)
end)

AddEventHandler('esx:setJob', function(playerId, job)
    local src = tonumber(playerId)
    if not src then return end

    local entry = PLAYER_CACHE[src] or {}
    local oldJob = entry.job
    if oldJob and JOB_INDEX[oldJob] then
        JOB_INDEX[oldJob][src] = nil
    end

    local newJob = (job and job.name) or 'unemployed'
    JOB_INDEX[newJob] = JOB_INDEX[newJob] or {}
    JOB_INDEX[newJob][src] = true

    entry.job = newJob
    PLAYER_CACHE[src] = entry
end)

AddEventHandler('playerDropped', function()
    removePlayerCache(source)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= ResourceName then return end
    flushPendingDamage()
    flushWriteQueue()
end)

CreateThread(function()
    registerTask('flush_damage', DamageFlushIntervalMs, flushPendingDamage)
    registerTask('flush_write_queue', WriteFlushIntervalMs, flushWriteQueue)
    registerTask('cleanup_cooldowns', 5000, function()
        local now = nowMs()

        for plate, readyAt in pairs(poundBroadcastCooldowns) do
            if now >= (tonumber(readyAt) or 0) then
                poundBroadcastCooldowns[plate] = nil
            end
        end

        for src, readyAt in pairs(reloadDispatchAt) do
            if now >= (tonumber(readyAt) or 0) then
                reloadDispatchAt[src] = nil
            end
        end
    end)

    while true do
        local now = nowMs()
        for i = 1, #TASK_SCHEDULER do
            local task = TASK_SCHEDULER[i]
            if now >= task.nextRun then
                task.nextRun = now + task.interval
                local ok, err = pcall(task.handler)
                if not ok then
                    print(('[%s] scheduler task failed (%s): %s'):format(ResourceName, task.name, tostring(err)))
                end
            end
        end
        Wait(500)
    end
end)

CreateThread(function()
    while not ESX do Wait(200) end

    dbExecute([[
        CREATE TABLE IF NOT EXISTS apex_custom_props (
            plate VARCHAR(32) PRIMARY KEY,
            props LONGTEXT,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ]])

    dbExecute('CREATE INDEX IF NOT EXISTS idx_owned_vehicles_owner ON owned_vehicles (owner)')
    dbExecute('CREATE INDEX IF NOT EXISTS idx_owned_vehicles_plate ON owned_vehicles (plate)')

    ESX.RegisterServerCallback(ResourceName..':payMoney', function(src, cb)
        local xPlayer = getPlayer(src)
        if not xPlayer then cb(false) return end

        local cost = tonumber(Config.poundCost or 0) or 0
        if cost <= 0 then cb(true) return end

        local money = xPlayer.getMoney()
        if money >= cost then
            xPlayer.removeMoney(cost)
            cb(true)
            return
        end

        local bank = xPlayer.getAccount('bank').money or 0
        if bank >= cost then
            xPlayer.removeAccountMoney('bank', cost)
            cb(true)
        else
            cb(false)
        end
    end)
end)
