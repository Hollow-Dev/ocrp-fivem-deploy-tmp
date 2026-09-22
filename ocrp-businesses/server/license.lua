local QBCore = exports['qb-core']:GetCoreObject()

local function getLicences(Player)
    local meta = Player.PlayerData.metadata or {}
    local licences = meta.licences or {}
    if type(licences) ~= 'table' then licences = {} end
    return licences
end

local function hasWeaponLicense(Player)
    local licences = getLicences(Player)
    return licences.weapon == true
end

QBCore.Functions.CreateCallback('ocrp-businesses:server:hasWeaponLicense', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then cb(false) return end
    cb(hasWeaponLicense(Player))
end)

RegisterNetEvent('ocrp-businesses:server:buyWeaponLicense', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local cfg = Config.WeaponLicense or {}
    if not cfg.enabled then
        TriggerClientEvent('QBCore:Notify', src, 'Weapons licensing is disabled.', 'error')
        return
    end

    if hasWeaponLicense(Player) then
        TriggerClientEvent('QBCore:Notify', src, 'You already have a firearms license.', 'error')
        return
    end

    local price = tonumber(cfg.price) or 2500
    local cash = Player.PlayerData.money.cash or 0
    local bank = Player.PlayerData.money.bank or 0

    if cash >= price then
        Player.Functions.RemoveMoney('cash', price, 'weapons-license')
    elseif bank >= price then
        Player.Functions.RemoveMoney('bank', price, 'weapons-license')
    else
        TriggerClientEvent('QBCore:Notify', src, ('You need $%s for a firearms license.'):format(price), 'error')
        return
    end

    local licences = getLicences(Player)
    licences.weapon = true
    Player.Functions.SetMetaData('licences', licences)

    TriggerClientEvent('QBCore:Notify', src, ('Firearms license purchased for $%s.'):format(price), 'success')
end)
