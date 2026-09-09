OnlineAdmins = 0
local LastPosition = {}
local LastJob = {}

AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() ~= resource then return end

    -- The character table is `users` on ESX and `players` on QBCore and Qbox,
    -- so the column is added to whichever one is actually there. Hard coding
    -- `users` meant the ALTER silently failed on the other two, and every
    -- player counted as not new from then on.
    local tbl = MSK.Offline.GetPlayerTable()

    if tbl then
        MySQL.query.await(("ALTER TABLE `%s` ADD COLUMN IF NOT EXISTS `isNew` varchar(1) DEFAULT '1';"):format(tbl.table))
    end

    if not Config.Admin.enable then return end

    for _, xPlayer in pairs(MSK.GetPlayers() or {}) do
        if MSK.TableContains(Config.AdminGroups, xPlayer.group) then
            OnlineAdmins = OnlineAdmins + 1
        end
    end

    TriggerClientEvent("msk_whitelist:refreshOnlineAdmin", -1, OnlineAdmins > 0)
end)

-- msk_core turns every framework's own load event into this one, and it is a
-- server-local event: AddEventHandler, not RegisterNetEvent, or any client
-- could fire it with an arbitrary player id and skew the admin counter.
AddEventHandler('msk_core:playerLoaded', function(playerId, xPlayer)
    local src = playerId

    if MSK.TableContains(Config.AdminGroups, xPlayer.group) then
        OnlineAdmins = OnlineAdmins + 1
    end
    TriggerClientEvent("msk_whitelist:refreshOnlineAdmin", src, OnlineAdmins > 0)

    local isNewPlayer = isPlayerNew(src)
    TriggerClientEvent("msk_whitelist:isNew", src, isNewPlayer)
    if not isNewPlayer then return end

    local xPlayers = MSK.GetPlayers()
    for k, Player in pairs(xPlayers) do
        if MSK.TableContains(Config.AdminGroups, Player.group) then
            Config.Notification(Player.source, Translation[Config.Locale]['newPlayerLogin']:format(GetPlayerName(src), src))
        end
    end
end)

AddEventHandler('msk_core:playerLogout', function(playerId)
    if not Config.Admin.enable then return end
    local src = playerId
    local xPlayer = MSK.GetPlayer(src)

    -- On a logout the character may already be gone, and indexing that nil
    -- ended the handler before it could update the counter.
    if not xPlayer then return end

    if MSK.TableContains(Config.AdminGroups, xPlayer.group) then
        OnlineAdmins = OnlineAdmins - 1
    end

    TriggerClientEvent("msk_whitelist:refreshOnlineAdmin", src, OnlineAdmins > 0)
end)

-- playerDropped is a FiveM event, not a framework one, so it stays. It fires
-- for a disconnect, while msk_core:playerLogout covers a character switch.
AddEventHandler('playerDropped', function(reason)
    if not Config.Admin.enable then return end
	local src = source
	local xPlayer = MSK.GetPlayer(src)

	-- Same here: a dropping player is often gone from the framework already.
	if not xPlayer then return end

	if MSK.TableContains(Config.AdminGroups, xPlayer.group) then
        OnlineAdmins = OnlineAdmins - 1
    end

    TriggerClientEvent("msk_whitelist:refreshOnlineAdmin", src, OnlineAdmins > 0)
end)

RegisterNetEvent('msk_whitelist:notifyAdmins', function(serverId)
    Config.Notification(source, Translation[Config.Locale]['bell_notify_player'])
    local xPlayers = MSK.GetPlayers()
    
    for k, xPlayer in pairs(xPlayers) do
        if MSK.TableContains(Config.AdminGroups, xPlayer.group) then
            Config.Notification(xPlayer.source, Translation[Config.Locale]['bell_notify_admins']:format(serverId))
        end
    end
end)

RegisterServerEvent('msk_whitelist:markertp', function()
    local src = source
    local xPlayer = MSK.GetPlayer(src)

    whitelistPlayer(nil, {source = src})
    sendDiscordLog(nil, xPlayer, true)
end)

RegisterServerEvent('msk_whitelist:banPlayer', function()
    local src = source
    local xPlayer = MSK.GetPlayer(src)
    
    if Config.BanPlayer and Config.BanPlayer.enable then
        local timestamp, timestring = 10444633200, tostring(Config.BanPlayer.time) .. 'H'

        if Config.BanPlayer.time == 'perma' then
            timestamp = 10444633200
            timestring = 'P'
        else
            timestamp = os.time() + (60 * 60 * tonumber(Config.BanPlayer.time))
        end

        Config.BanFunction(xPlayer, Config.BanString, timestamp, timestring)
    end
end)

-- MSK.RegisterCommand instead of ESX.RegisterCommand: same idea, but it works
-- on every framework and resolves the ace groups itself. returnPlayer hands
-- over the calling player as an object, the way the ESX version did.
MSK.RegisterCommand(Config.Commands.einreise, function(xPlayer, args, raw)
    local xTarget = args.player

    if not isPlayerNew(xTarget.source) then 
        return Config.Notification(xPlayer.source, Translation[Config.Locale]['isWhitelisted']:format(xTarget.source))
    end

    TriggerClientEvent('msk_whitelist:isNew', xTarget.source, false)
    TriggerClientEvent('msk_whitelist:einreise', xTarget.source, Config.Locations.einreise)
    
    Config.Notification(xTarget.source, Translation[Config.Locale]['welcome'])
    Config.Notification(xPlayer.source, Translation[Config.Locale]['admin_success']:format(xTarget.source))
    
    sendDiscordLog(xPlayer, xTarget)

    local tbl = MSK.Offline.GetPlayerTable()

    if tbl then
        MySQL.update(("UPDATE `%s` SET `isNew` = 0 WHERE `%s` = ?"):format(tbl.table, tbl.identifier), {
            xTarget.identifier
        })
    end
end, {
    allowConsole = false,
    restricted = Config.AdminGroups,
    returnPlayer = true,
    help = Translation[Config.Locale]['einreise'],
    params = {
        { name = 'player', help = 'PlayerID', type = 'player' },
    },
})

MSK.RegisterCommand(Config.Commands.ausreise.command, function(xPlayer, args, raw)
    local xTarget = args.player
    local ausreise = Config.Commands.ausreise

    if ausreise.teleport then
        TriggerClientEvent('msk_whitelist:einreise', xTarget.source, Config.Locations.player_back_in)
    end
    TriggerClientEvent('msk_whitelist:isNew', xTarget.source, true)

    -- ClearInventory empties the inventory on every framework. On ox_inventory
    -- that includes the weapons, because they are items there; on the ESX
    -- default inventory msk_core clears the separate loadout as well. The two
    -- config switches therefore end up doing the same thing on a modern setup.
    if ausreise.clear_inventory or ausreise.clear_weapons then
        xTarget.ClearInventory()
    end

    -- The starting balance comes from this resource's config now. It used to
    -- be read from ESX.GetConfig().StartingAccountMoney, which QBCore and Qbox
    -- do not have, and the account names differ too (black_money vs crypto).
    -- Unknown accounts are skipped rather than guessed at.
    if ausreise.clear_money then
        for account, amount in pairs(Config.Commands.ausreise.startMoney or {}) do
            xTarget.SetMoney(account, tonumber(amount) or 0)
        end
    end

    Config.Notification(xTarget.source, Translation[Config.Locale]['bye'])
    Config.Notification(xPlayer.source, Translation[Config.Locale]['admin_success_ausreise']:format(xTarget.source))

    sendDiscordLog(xPlayer, xTarget, 'ausreise')

    local tbl = MSK.Offline.GetPlayerTable()

    if tbl then
        MySQL.update(("UPDATE `%s` SET `isNew` = 1 WHERE `%s` = ?"):format(tbl.table, tbl.identifier), {
            xTarget.identifier
        })
    end
    
    if Config.Commands.ausreise.banPlayer and Config.Commands.ausreise.banPlayer.enable then
        Wait(500)
        local timestamp, timestring = 10444633200, tostring(Config.Commands.ausreise.banPlayer.time) .. 'H'

        if Config.Commands.ausreise.banPlayer.time == 'perma' then
            timestamp = 10444633200
            timestring = 'P'
        else
            timestamp = os.time() + (60 * 60 * tonumber(Config.Commands.ausreise.banPlayer.time))
        end

        Config.BanFunction(xTarget, Config.BanString2, timestamp, timestring)
    end
end, {
    allowConsole = false,
    restricted = Config.AdminGroups,
    returnPlayer = true,
    help = Translation[Config.Locale]['ausreise'],
    params = {
        { name = 'player', help = 'PlayerID', type = 'player' },
    },
})

RegisterCommand(Config.Commands.admin_inside, function(source, args, rawCommand)
    local src = source
    local xPlayer = MSK.GetPlayer(src)

    -- Plain RegisterCommand, so this can also come from the server console,
    -- where there is no player to read a group from.
    if not xPlayer then return end

    if not MSK.TableContains(Config.AdminGroups, xPlayer.group) then
        return Config.Notification(xPlayer.source, Translation[Config.Locale]['no_rights'])
    end

    if not args[1] then args[1] = src end
    local xTarget = MSK.GetPlayer(args[1])

    if not xTarget then return end

    if Config.Locations.admin_outside == 'last_position' then
        -- GetCoords, not getCoords: the ESX method is gone with msk_core 4.0.0.
        LastPosition[xTarget.source] = xTarget.GetCoords()
    end

    TriggerClientEvent('msk_whitelist:einreise', xTarget.source, Config.Locations.admin_inside)
    TriggerClientEvent('msk_whitelist:toggleNametags', xTarget.source, true)
    TriggerClientEvent('msk_whitelist:setClothing', xTarget.source, true)
    Config.Notification(xTarget.source, Translation[Config.Locale]['rein'])
end)

RegisterCommand(Config.Commands.admin_outside, function(source, args, rawCommand)
    local src = source
    local xPlayer = MSK.GetPlayer(src)

    if not xPlayer then return end

    if not MSK.TableContains(Config.AdminGroups, xPlayer.group) then
        return Config.Notification(xPlayer.source, Translation[Config.Locale]['no_rights'])
    end

    if not args[1] then args[1] = src end
    local xTarget = MSK.GetPlayer(args[1])

    if not xTarget then return end

    -- Without a stored position there is nothing to send back to, and the
    -- client would index a nil. Falls back to the configured location.
    if Config.Locations.admin_outside == 'last_position' and LastPosition[xTarget.source] then
        TriggerClientEvent('msk_whitelist:einreise', xTarget.source, LastPosition[xTarget.source])
        LastPosition[xTarget.source] = nil
    elseif Config.Locations.admin_outside == 'last_position' then
        TriggerClientEvent('msk_whitelist:einreise', xTarget.source, Config.Locations.admin_inside)
    else
        TriggerClientEvent('msk_whitelist:einreise', xTarget.source, Config.Locations.admin_outside)
    end

    TriggerClientEvent('msk_whitelist:toggleNametags', xTarget.source, false)
    TriggerClientEvent('msk_whitelist:setClothing', xTarget.source, false)
    Config.Notification(xTarget.source, Translation[Config.Locale]['raus'])
end)

MSK.Register('msk_whitelist:getOnlineAdmins', function(source)
    return OnlineAdmins > 0
end)

MSK.Register('msk_whitelist:getPlayerIsNew', function(source, playerId)
    local src = source
    if playerId then src = playerId end
    return isPlayerNew(src)
end)