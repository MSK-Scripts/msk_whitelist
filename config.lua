Config = {}
----------------------------------------------------------------
Config.Locale = 'de'
Config.VersionChecker = true
Config.Debug = true
----------------------------------------------------------------
-- Add the Webhook Link in server_discordlog.lua
Config.DiscordLog = true
Config.botColor = "6205745" -- https://www.mathsisfun.com/hexadecimal-decimal-colors.html
Config.botName = "MSK Scripts"
Config.botAvatar = "https://i.imgur.com/PizJGsh.png"
----------------------------------------------------------------
-- !!! This function is clientside AND serverside !!!
Config.Notification = function(source, message, typ, duration)
    if IsDuplicityVersion() then -- serverside
        MSK.Notification(source, 'MSK Whitelist', message, typ, duration)
    else -- clientside
        MSK.Notification('MSK Whitelist', message, typ, duration)
    end
end
----------------------------------------------------------------
Config.Locations = {
    -- !!! admin_outside = 'last_position' ONLY works if you use OneSync !!!

    einreise = vector3(-1042.46, -2745.62, 21.36),
    admin_inside = vector3(-1082.14, -2826.92, 27.71),
    admin_outside = 'last_position', -- 'last_position' or vector3(-1042.46, -2745.62, 21.36)
    player_back_in = vector3(-1129.47, -2788.55, 27.71), -- Position were the Player get teleported back if the Player is not whitelisted
    bell = {enable = true, distance = 10.0, size = 0.5, location = vector3(-1084.69, -2831.37, 27.60), timeout = 10} -- Postition for a bell where new players can Notify Admins
}

Config.NameTags = {
    enable = true, -- Set false to deactive Nametags // With admin_inside Command it will be activated and with Command admin_outside it will be deactivated
    distance = 10.0, -- Distance between you and the Player to show ID and Name
    showHealth = true, -- Set false to deactivate Healthbar
    showOwnID = true -- Set to false if you don't want to show your own ID and Name
}

Config.TPBackDistance = 150 
Config.AdminGroups = {'superadmin', 'admin'}

Config.Commands = {
    einreise = 'einreise', -- Whitelist someone // Usage: /einreise ID
    admin_inside = 'rein', -- Enter the Bordercontrol // Usage: /rein ID (ID is optional)
    admin_outside = 'raus', -- Leave the Bordercontrol // Usage: /raus ID (ID is optional)
    ausreise = {
        command = 'ausreise', -- Sets the Whitelist to false in database // Usage: /ausreise ID
        teleport = true, -- Teleports the Player back to player_back_in Location
        clear_inventory = true, -- Removes all Items
        clear_weapons = true, -- Removes all Weapons
        clear_money = true, -- Set money to Default Money [es_extended config]
        banPlayer = {enable = true, time = 2 --[[in hours or set to 'perma']]} -- Bans the player
    }
}

Config.BanPlayer = {enable = true, time = 'perma' --[[in hours or set to 'perma']]} -- Ban Player if he try to get out of the TPBackDistance Range
Config.BanString = 'Banned by MSK Einreise (tried to glitch out of Airport)'
Config.BanString2 = 'Banned by MSK Einreise (executed ' .. Config.Commands.ausreise.command .. ' Command)'
Config.BanFunction = function(xPlayer, reason, timestamp, timestring)
    -- !!! This funtion is SERVERSIDE !!!
    -- timestring is something like '2H' made for msk_bansystem (https://forum.cfx.re/t/standalone-msk-bansystem/5126481)
    local playerId = xPlayer.source
    local identifier = xPlayer.identifier

    exports.msk_bansystem:banPlayer(nil, playerId, timestring, reason)
end
----------------------------------------------------------------
Config.Marker = {
    enable = true, -- Displays a marker
    type = 27, 
    size = {a = 1.0, b = 1.0, c = 1.0}, 
    color = {a = 255, b = 255, c = 255},
    distance = 10.0,
    text3d = {enable = true, string = '~g~E~w~ - Einreisen', size = 1.0,},
    coords = { -- You can set multiple markers
        vector3(-1065.74, -2798.57, 27.71)
    },
    hotkey = 38 -- default: 38 = E
}
----------------------------------------------------------------
Config.Admin = {
    enable = true, -- Checks if a admin is online and then deactivates the Marker and draws another 3DText if Marker and tex3d is enabled
    enableMarker = true, -- Displays a Marker if no Admin is online
    text3d = {
        enable = true, -- Set false to deactivate the 3D Text
        string_adminOnline = '~g~Beamte im Dienst~w~ - Es wird sich gleich um dich gekümmert', 
        string_adminOffline = '~g~Kein Beamter da!~w~ - Lauf hier lang zum Marker', 
        size = 0.8, 
        distance = 10.0,
        coords = { -- You can set multiple markers
            vector3(-1084.69, -2831.37, 27.71)
        }
    },
}
----------------------------------------------------------------
Config.AdminProtection = {
    setArmor = 100, -- Set false to deactivate it or set to a number between 1 and 100
    setGodmode = true, -- Set false to deactivate it
    disableCanRagdoll = true, -- Set to true means disabled Ragdoll
    disableCanBeDamaged = true, -- Set to true means disabled Damage
}

Config.Clothing = {
    enable = true, -- Set false to deactivate this feature

    male = {
        ['tshirt_1'] = 15,  ['tshirt_2'] = 0,
        ['torso_1'] = 287,  ['torso_2'] = 2,
        ['decals_1'] = 0,   ['decals_2'] = 0,
        ['arms'] = 3,
        ['pants_1'] = 114,  ['pants_2'] = 2,
        ['shoes_1'] = 78,   ['shoes_2'] = 2,
        ['helmet_1'] = -1,  ['helmet_2'] = 0,
        ['mask_1'] = 135,   ['mask_2'] = 2,
        ['chain_1'] = 0,    ['chain_2'] = 0,
        ['ears_1'] = 0,     ['ears_2'] = 0,
        ['bags_1'] = 0,     ['bags_2'] = 0,
        ['hair_1'] = 0,     ['hair_2'] = 0,
        ['bproof_1'] = 0,   ['bproof_2'] = 0
    },
    female = {
        ['tshirt_1'] = 15,  ['tshirt_2'] = 0,
        ['torso_1'] = 300,  ['torso_2'] = 9,
        ['decals_1'] = 0,   ['decals_2'] = 0,
        ['arms'] = 8,
        ['pants_1'] = 121,  ['pants_2'] = 9,
        ['shoes_1'] = 82,   ['shoes_2'] = 9,
        ['helmet_1'] = 23,  ['helmet_2'] = 0,
        ['mask_1'] = 135,   ['mask_2'] = 9,
        ['chain_1'] = 0,    ['chain_2'] = 0,
        ['ears_1'] = 0,     ['ears_2'] = 0,
        ['bags_1'] = 0,     ['bags_2'] = 0,
        ['hair_1'] = 0,     ['hair_2'] = 0,
        ['bproof_1'] = 0,   ['bproof_2'] = 0
    }
}