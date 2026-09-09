fx_version 'cerulean'
games { 'gta5' }

author 'Musiker15 - MSK Scripts'
name 'msk_whitelist'
description 'Ingame Whitelist'
version '2.1.0'

lua54 'yes'

escrow_ignore {
	'config.lua',
	'translation.lua',

    'client/main.lua',
    'server/main.lua',
    'server/functions.lua',
    'server/discordlog.lua',
}

shared_scripts {
    -- @es_extended/imports.lua is gone: framework calls run through
    -- msk_core, and importing ESX here made the resource refuse to start
    -- on a server without it.
    '@msk_core/import.lua',
    'config.lua',
    'translation.lua',
}

client_scripts {
	'client/**/*.*'
}

server_script {
    '@oxmysql/lib/MySQL.lua',
    'server/**/*.*'
}

dependencies {
    'oxmysql',
    'msk_core'
}