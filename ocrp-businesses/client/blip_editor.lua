local QBCore = exports['qb-core']:GetCoreObject()
local customBlipHandles = {}
local editorOpen = false
local previewBlip = nil

local COMMON_SPRITES = {
    { id = 1, label = 'Standard' },
    { id = 50, label = 'Garage' },
    { id = 52, label = 'Store' },
    { id = 60, label = 'Police' },
    { id = 61, label = 'Hospital' },
    { id = 71, label = 'Barber' },
    { id = 72, label = 'Clothes' },
    { id = 73, label = 'Tattoo' },
    { id = 75, label = 'Clothes Alt' },
    { id = 100, label = 'Car Wash' },
    { id = 110, label = 'Gun Shop' },
    { id = 140, label = 'Weed' },
    { id = 225, label = 'Car' },
    { id = 226, label = 'Bike' },
    { id = 237, label = 'Helicopter' },
    { id = 251, label = 'Plane' },
    { id = 280, label = 'Person' },
    { id = 326, label = 'Dealership' },
    { id = 357, label = 'Parking' },
    { id = 361, label = 'Gas' },
    { id = 398, label = 'Bar' },
    { id = 402, label = 'Tools' },
    { id = 408, label = 'Info' },
    { id = 475, label = 'House' },
    { id = 478, label = 'Warehouse' },
    { id = 498, label = 'ID / License' },
    { id = 521, label = 'Battery' },
    { id = 536, label = 'Race' },
    { id = 590, label = 'Business' },
    { id = 614, label = 'Casino' },
    { id = 679, label = 'Dollar' },
}

local COMMON_COLORS = {
    { id = 0, label = 'White' },
    { id = 1, label = 'Red' },
    { id = 2, label = 'Green' },
    { id = 3, label = 'Blue' },
    { id = 5, label = 'Yellow' },
    { id = 7, label = 'Violet' },
    { id = 8, label = 'Pink' },
    { id = 17, label = 'Orange' },
    { id = 27, label = 'Dark Blue' },
    { id = 29, label = 'Light Blue' },
    { id = 38, label = 'Teal' },
    { id = 39, label = 'Light Green' },
    { id = 46, label = 'Gold' },
    { id = 47, label = 'Orange Dark' },
    { id = 49, label = 'Purple' },
}

local function clearCustomBlips()
    for _, handle in pairs(customBlipHandles) do
        if DoesBlipExist(handle) then
            RemoveBlip(handle)
        end
    end
    customBlipHandles = {}
end

local function clearPreview()
    if previewBlip and DoesBlipExist(previewBlip) then
        RemoveBlip(previewBlip)
    end
    previewBlip = nil
end

local function showPreview(coords, sprite, color, scale, name)
    clearPreview()
    previewBlip = AddBlipForCoord(coords.x + 0.0, coords.y + 0.0, coords.z + 0.0)
    SetBlipSprite(previewBlip, tonumber(sprite) or 1)
    SetBlipDisplay(previewBlip, 4)
    SetBlipScale(previewBlip, tonumber(scale) or 0.7)
    SetBlipColour(previewBlip, tonumber(color) or 0)
    SetBlipAsShortRange(previewBlip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(name or 'Preview')
    EndTextCommandSetBlipName(previewBlip)
    SetBlipRoute(previewBlip, true)
    QBCore.Functions.Notify(('Preview: sprite %s / color %s (route on map)'):format(sprite or 1, color or 0), 'primary', 4000)
end

local function spawnCustomBlips(list)
    clearCustomBlips()
    for _, row in ipairs(list or {}) do
        local blip = AddBlipForCoord(row.x + 0.0, row.y + 0.0, row.z + 0.0)
        SetBlipSprite(blip, tonumber(row.sprite) or 1)
        SetBlipDisplay(blip, 4)
        SetBlipScale(blip, tonumber(row.scale) or 0.7)
        SetBlipColour(blip, tonumber(row.color) or 0)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(row.name or 'Custom')
        EndTextCommandSetBlipName(blip)
        customBlipHandles[tonumber(row.id) or #customBlipHandles + 1] = blip
    end
end

RegisterNetEvent('ocrp-businesses:client:setCustomBlips', function(list)
    spawnCustomBlips(list)
end)

CreateThread(function()
    Wait(2000)
    QBCore.Functions.TriggerCallback('ocrp-businesses:server:getCustomBlips', function(list)
        spawnCustomBlips(list)
    end)
end)

local function pickSprite(cb)
    local menu = { { header = 'Pick Blip Icon', isMenuHeader = true } }
    for _, s in ipairs(COMMON_SPRITES) do
        menu[#menu + 1] = {
            header = ('[%s] %s'):format(s.id, s.label),
            txt = 'Preview this sprite at your feet',
            params = {
                event = 'ocrp-businesses:client:blipPickedSprite',
                args = { id = s.id, cbId = cb },
            },
        }
    end
    menu[#menu + 1] = {
        header = 'Enter custom sprite ID',
        params = { event = 'ocrp-businesses:client:blipCustomSprite', args = { cbId = cb } },
    }
    menu[#menu + 1] = { header = 'Close', params = { event = 'qb-menu:client:closeMenu' } }
    exports['qb-menu']:openMenu(menu)
end

local function pickColor(cb)
    local menu = { { header = 'Pick Blip Color', isMenuHeader = true } }
    for _, c in ipairs(COMMON_COLORS) do
        menu[#menu + 1] = {
            header = ('[%s] %s'):format(c.id, c.label),
            txt = 'Preview this color at your feet',
            params = {
                event = 'ocrp-businesses:client:blipPickedColor',
                args = { id = c.id, cbId = cb },
            },
        }
    end
    menu[#menu + 1] = {
        header = 'Enter custom color ID',
        params = { event = 'ocrp-businesses:client:blipCustomColor', args = { cbId = cb } },
    }
    menu[#menu + 1] = { header = 'Close', params = { event = 'qb-menu:client:closeMenu' } }
    exports['qb-menu']:openMenu(menu)
end

local pendingPick = {}

RegisterNetEvent('ocrp-businesses:client:blipPickedSprite', function(data)
    if not data then return end
    local coords = GetEntityCoords(PlayerPedId())
    showPreview(coords, data.id, 0, 0.85, 'Icon Preview')
    local fn = pendingPick[data.cbId]
    pendingPick[data.cbId] = nil
    if fn then fn(data.id) end
end)

RegisterNetEvent('ocrp-businesses:client:blipPickedColor', function(data)
    if not data then return end
    local coords = GetEntityCoords(PlayerPedId())
    showPreview(coords, 1, data.id, 0.85, 'Color Preview')
    local fn = pendingPick[data.cbId]
    pendingPick[data.cbId] = nil
    if fn then fn(data.id) end
end)

RegisterNetEvent('ocrp-businesses:client:blipCustomSprite', function(data)
    local dialog = exports['qb-input']:ShowInput({
        header = 'Custom Sprite ID',
        submitText = 'Use',
        inputs = { { type = 'number', isRequired = true, name = 'sprite', text = 'Sprite ID' } },
    })
    if not dialog or not dialog.sprite then return end
    local id = tonumber(dialog.sprite) or 1
    local coords = GetEntityCoords(PlayerPedId())
    showPreview(coords, id, 0, 0.85, 'Icon Preview')
    local fn = pendingPick[data and data.cbId]
    pendingPick[data and data.cbId] = nil
    if fn then fn(id) end
end)

RegisterNetEvent('ocrp-businesses:client:blipCustomColor', function(data)
    local dialog = exports['qb-input']:ShowInput({
        header = 'Custom Color ID',
        submitText = 'Use',
        inputs = { { type = 'number', isRequired = true, name = 'color', text = 'Color ID' } },
    })
    if not dialog or not dialog.color then return end
    local id = tonumber(dialog.color) or 0
    local coords = GetEntityCoords(PlayerPedId())
    showPreview(coords, 1, id, 0.85, 'Color Preview')
    local fn = pendingPick[data and data.cbId]
    pendingPick[data and data.cbId] = nil
    if fn then fn(id) end
end)

local function placeBlipAtPlayer()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    print(('[ocrp-blipeditor] vector4(%.2f, %.2f, %.2f, %.2f)'):format(coords.x, coords.y, coords.z, GetEntityHeading(ped)))

    local sprite, color = 1, 0
    local cbSprite = ('s_%s'):format(math.random(100000, 999999))
    pendingPick[cbSprite] = function(sid)
        sprite = sid
        local cbColor = ('c_%s'):format(math.random(100000, 999999))
        pendingPick[cbColor] = function(cid)
            color = cid
            showPreview(coords, sprite, color, 0.85, 'New Blip Preview')
            local dialog = exports['qb-input']:ShowInput({
                header = 'Place Custom Blip',
                submitText = 'Save',
                inputs = {
                    { type = 'text', isRequired = true, name = 'name', text = 'Blip Name' },
                    { type = 'number', isRequired = false, name = 'sprite', text = ('Sprite (preview %s)'):format(sprite), default = sprite },
                    { type = 'number', isRequired = false, name = 'color', text = ('Color (preview %s)'):format(color), default = color },
                    { type = 'text', isRequired = false, name = 'scale', text = 'Scale (default 0.7)' },
                },
            })
            clearPreview()
            if not dialog or not dialog.name then return end
            TriggerServerEvent('ocrp-businesses:server:saveBlip', {
                name = dialog.name,
                sprite = tonumber(dialog.sprite) or sprite,
                color = tonumber(dialog.color) or color,
                scale = tonumber(dialog.scale) or 0.7,
                x = coords.x,
                y = coords.y,
                z = coords.z,
            })
        end
        pickColor(cbColor)
    end
    pickSprite(cbSprite)
end

local function editBlipRow(row)
    showPreview(vector3(row.x + 0.0, row.y + 0.0, row.z + 0.0), row.sprite, row.color, row.scale, row.name)
    local dialog = exports['qb-input']:ShowInput({
        header = ('Edit Blip #%s'):format(row.id),
        submitText = 'Update',
        inputs = {
            { type = 'text', isRequired = true, name = 'name', text = 'Blip Name', default = row.name },
            { type = 'number', isRequired = true, name = 'sprite', text = 'Sprite ID', default = row.sprite },
            { type = 'number', isRequired = true, name = 'color', text = 'Color ID', default = row.color },
            { type = 'text', isRequired = false, name = 'scale', text = 'Scale', default = tostring(row.scale or 0.7) },
            { type = 'text', isRequired = false, name = 'movehere', text = 'Type YES to move to your coords' },
        },
    })
    clearPreview()
    if not dialog or not dialog.name then return end

    local x, y, z = row.x, row.y, row.z
    if dialog.movehere and tostring(dialog.movehere):lower() == 'yes' then
        local c = GetEntityCoords(PlayerPedId())
        x, y, z = c.x, c.y, c.z
    end

    TriggerServerEvent('ocrp-businesses:server:updateBlip', {
        id = row.id,
        name = dialog.name,
        sprite = tonumber(dialog.sprite) or row.sprite,
        color = tonumber(dialog.color) or row.color,
        scale = tonumber(dialog.scale) or row.scale or 0.7,
        x = x,
        y = y,
        z = z,
    })
end

local function editBlipMenu()
    QBCore.Functions.TriggerCallback('ocrp-businesses:server:getCustomBlips', function(list)
        local menu = { { header = 'Edit Custom Blip', isMenuHeader = true } }
        for _, row in ipairs(list or {}) do
            menu[#menu + 1] = {
                header = ('#%s %s'):format(row.id, row.name),
                txt = ('sprite %s | color %s | scale %s'):format(row.sprite, row.color, row.scale),
                params = {
                    event = 'ocrp-businesses:client:editBlipRow',
                    args = row,
                },
            }
        end
        menu[#menu + 1] = { header = 'Close', params = { event = 'qb-menu:client:closeMenu' } }
        exports['qb-menu']:openMenu(menu)
    end)
end

local function deleteBlipMenu()
    QBCore.Functions.TriggerCallback('ocrp-businesses:server:getCustomBlips', function(list)
        local menu = { { header = 'Delete Custom Blip', isMenuHeader = true } }
        for _, row in ipairs(list or {}) do
            menu[#menu + 1] = {
                header = ('#%s %s'):format(row.id, row.name),
                txt = ('sprite %s color %s'):format(row.sprite, row.color),
                params = {
                    event = 'ocrp-businesses:client:confirmDeleteBlip',
                    args = { id = row.id },
                },
            }
        end
        menu[#menu + 1] = { header = 'Close', params = { event = 'qb-menu:client:closeMenu' } }
        exports['qb-menu']:openMenu(menu)
    end)
end

local function previewBrowser()
    local menu = {
        { header = 'Preview Icons / Colors', isMenuHeader = true },
        {
            header = 'Browse icons (sprites)',
            txt = 'Shows a preview blip at your feet',
            params = { event = 'ocrp-businesses:client:blipEditorAction', args = { action = 'preview_sprite' } },
        },
        {
            header = 'Browse colors',
            txt = 'Shows a preview blip at your feet',
            params = { event = 'ocrp-businesses:client:blipEditorAction', args = { action = 'preview_color' } },
        },
        {
            header = 'Clear preview',
            params = { event = 'ocrp-businesses:client:blipEditorAction', args = { action = 'clear_preview' } },
        },
        { header = 'Close', params = { event = 'qb-menu:client:closeMenu' } },
    }
    exports['qb-menu']:openMenu(menu)
end

RegisterNetEvent('ocrp-businesses:client:editBlipRow', function(row)
    if row then editBlipRow(row) end
end)

RegisterNetEvent('ocrp-businesses:client:confirmDeleteBlip', function(data)
    if data and data.id then
        TriggerServerEvent('ocrp-businesses:server:deleteBlip', data.id)
    end
end)

RegisterNetEvent('ocrp-businesses:client:openBlipEditor', function()
    if editorOpen then return end
    editorOpen = true
    local menu = {
        { header = 'Blip Editor (Admin)', isMenuHeader = true },
        {
            header = 'Place blip at my coords',
            txt = 'Pick icon/color with live preview, then save',
            params = { event = 'ocrp-businesses:client:blipEditorAction', args = { action = 'place' } },
        },
        {
            header = 'Edit existing blip',
            txt = 'Change name, icon, color, scale, or move here',
            params = { event = 'ocrp-businesses:client:blipEditorAction', args = { action = 'edit' } },
        },
        {
            header = 'Preview icons / colors',
            txt = 'Browse sprites and colors before placing',
            params = { event = 'ocrp-businesses:client:blipEditorAction', args = { action = 'preview' } },
        },
        {
            header = 'Delete custom blip',
            params = { event = 'ocrp-businesses:client:blipEditorAction', args = { action = 'delete' } },
        },
        { header = 'Close', params = { event = 'qb-menu:client:closeMenu' } },
    }
    exports['qb-menu']:openMenu(menu)
    editorOpen = false
end)

RegisterNetEvent('ocrp-businesses:client:blipEditorAction', function(data)
    if not data then return end
    if data.action == 'place' then
        placeBlipAtPlayer()
    elseif data.action == 'edit' then
        editBlipMenu()
    elseif data.action == 'delete' then
        deleteBlipMenu()
    elseif data.action == 'preview' then
        previewBrowser()
    elseif data.action == 'preview_sprite' then
        local cbId = ('ps_%s'):format(math.random(100000, 999999))
        pendingPick[cbId] = function(_) end
        pickSprite(cbId)
    elseif data.action == 'preview_color' then
        local cbId = ('pc_%s'):format(math.random(100000, 999999))
        pendingPick[cbId] = function(_) end
        pickColor(cbId)
    elseif data.action == 'clear_preview' then
        clearPreview()
        QBCore.Functions.Notify('Preview cleared.', 'success')
    end
end)
