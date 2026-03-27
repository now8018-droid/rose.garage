GarageModules = GarageModules or {}
GarageModules.UI = GarageModules.UI or {}

function GarageModules.UI.syncOwnedVehicleToClient(src, payload)
    if type(src) ~= 'number' then
        return false
    end

    if type(payload) ~= 'table' then
        return false
    end

    TriggerClientEvent('APEX-VehicleShop:Garage:SyncOwnedVehicle', src, payload)
    return true
end

exports('SyncOwnedVehicle', function(src, payload)
    return GarageModules.UI.syncOwnedVehicleToClient(src, payload)
end)
