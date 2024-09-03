fx_version 'cerulean'
games { 'gta5' }

author 'Musiker15 - MSK Scripts'
name 'msk_whitelist'
description 'Ingame Whitelist'
version '2.0.1'

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
    '@es_extended/imports.lua',
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
    'es_extended',
    'oxmysql',
    'msk_core'
}