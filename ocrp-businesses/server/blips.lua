local QBCore = exports['qb-core']:GetCoreObject()

CreateThread(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `ocrp_blips` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `name` VARCHAR(128) NOT NULL,
            `sprite` INT NOT NULL DEFAULT 1,
            `color` INT NOT NULL DEFAULT 0,
            `scale` FLOAT NOT NULL DEFAULT 0.7,
            `x` FLOAT NOT NULL,
            `y` FLOAT NOT NULL,
            `z` FLOAT NOT NULL,
            `created_by` VARCHAR(64) DEFAULT NULL,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]])
end)

local function loadBlips()
    return MySQL.query.await('SELECT * FROM ocrp_blips') or {}
end

local function broadcastBlips()
    TriggerClientEvent('ocrp-businesses:client:setCustomBlips', -1, loadBlips())
end

RegisterNetEvent('ocrp-businesses:server:saveBlip', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if not QBCore.Functions.HasPermission(src, Config.AdminPermission) and not IsPlayerAceAllowed(src, 'command') then
        TriggerClientEvent('QBCore:Notify', src, 'No permission.', 'error')
        return
    end

    if type(data) ~= 'table' then return end
    local name = tostring(data.name or 'Custom Blip'):sub(1, 128)
    local sprite = math.floor(tonumber(data.sprite) or 1)
    local color = math.floor(tonumber(data.color) or 0)
    local scale = tonumber(data.scale) or 0.7
    local x = tonumber(data.x)
    local y = tonumber(data.y)
    local z = tonumber(data.z)
    if not x or not y or not z then return end

    MySQL.insert.await(
        'INSERT INTO ocrp_blips (name, sprite, color, scale, x, y, z, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        { name, sprite, color, scale, x, y, z, Player.PlayerData.citizenid }
    )

    local all = loadBlips()
    SaveResourceFile(GetCurrentResourceName(), 'custom_blips.json', json.encode(all), -1)

    TriggerClientEvent('QBCore:Notify', src, ('Saved blip "%s".'):format(name), 'success')
    broadcastBlips()
end)

RegisterNetEvent('ocrp-businesses:server:updateBlip', function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if not QBCore.Functions.HasPermission(src, Config.AdminPermission) and not IsPlayerAceAllowed(src, 'command') then
        TriggerClientEvent('QBCore:Notify', src, 'No permission.', 'error')
        return
    end

    if type(data) ~= 'table' then return end
    local id = tonumber(data.id)
    if not id then return end

    local name = tostring(data.name or 'Custom Blip'):sub(1, 128)
    local sprite = math.floor(tonumber(data.sprite) or 1)
    local color = math.floor(tonumber(data.color) or 0)
    local scale = tonumber(data.scale) or 0.7
    local x = tonumber(data.x)
    local y = tonumber(data.y)
    local z = tonumber(data.z)
    if not x or not y or not z then return end

    MySQL.update.await(
        'UPDATE ocrp_blips SET name = ?, sprite = ?, color = ?, scale = ?, x = ?, y = ?, z = ? WHERE id = ?',
        { name, sprite, color, scale, x, y, z, id }
    )

    local all = loadBlips()
    SaveResourceFile(GetCurrentResourceName(), 'custom_blips.json', json.encode(all), -1)
    TriggerClientEvent('QBCore:Notify', src, ('Updated blip "%s".'):format(name), 'success')
    broadcastBlips()
end)

RegisterNetEvent('ocrp-businesses:server:deleteBlip', function(blipId)
    local src = source
    if not QBCore.Functions.HasPermission(src, Config.AdminPermission) and not IsPlayerAceAllowed(src, 'command') then
        TriggerClientEvent('QBCore:Notify', src, 'No permission.', 'error')
        return
    end

    blipId = tonumber(blipId)
    if not blipId then return end

    MySQL.query.await('DELETE FROM ocrp_blips WHERE id = ?', { blipId })
    local all = loadBlips()
    SaveResourceFile(GetCurrentResourceName(), 'custom_blips.json', json.encode(all), -1)
    TriggerClientEvent('QBCore:Notify', src, 'Blip deleted.', 'success')
    broadcastBlips()
end)

QBCore.Functions.CreateCallback('ocrp-businesses:server:getCustomBlips', function(_, cb)
    cb(loadBlips())
end)

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetTimeout(1500, broadcastBlips)
end)

RegisterNetEvent('QBCore:Server:PlayerLoaded', function(_)
    local src = source
    TriggerClientEvent('ocrp-businesses:client:setCustomBlips', src, loadBlips())
end)
