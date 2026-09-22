fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'ocrp-businesses'
description 'Ocean County RP player-owned businesses'
author 'Ocean County RP'
version '1.0.0'

dependency 'qb-core'
dependency 'oxmysql'
dependency 'qb-target'

shared_script 'config.lua'

client_scripts {
    'client/main.lua',
    'client/blip_editor.lua',
    'client/license_ped.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/blips.lua',
    'server/license.lua',
}
