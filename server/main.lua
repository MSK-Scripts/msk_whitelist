OnlineAdmins = 0
local LastPosition = {}
local LastJob = {}

AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() ~= resource then return end
    MySQL.query.await("ALTER TABLE users ADD COLUMN IF NOT EXISTS `isNew` varchar(1) DEFAULT '1';")
    if not Config.Admin.enable then return end
    local xPlayers = ESX.GetExtendedPlayers()

    for k, xPlayer in ipairs(xPlayers) do
        if MSK.TableContains(Config.AdminGroups, xPlayer.group) then
            OnlineAdmins = OnlineAdmins + 1
        end
    end

    TriggerClientEvent("msk_whitelist:refreshOnlineAdmin", -1, OnlineAdmins > 0)
end)

RegisterNetEvent('esx:playerLoaded', function(playerId, xPlayer)
    local src = playerId

    if MSK.TableContains(Config.AdminGroups, xPlayer.group) then
        OnlineAdmins = OnlineAdmins + 1
    end
    TriggerClientEvent("msk_whitelist:refreshOnlineAdmin", src, OnlineAdmins > 0)

    local isNewPlayer = isPlayerNew(src)
    TriggerClientEvent("msk_whitelist:isNew", src, isNewPlayer)
    if not isNewPlayer then return end

    local xPlayers = ESX.GetExtendedPlayers()
    for k, Player in pairs(xPlayers) do
        if MSK.TableContains(Config.AdminGroups, Player.group) then
            Config.Notification(Player.source, Translation[Config.Locale]['newPlayerLogin']:format(GetPlayerName(src), src))
        end
    end
end)

RegisterNetEvent('esx:playerLogout', function(playerId)
    if not Config.Admin.enable then return end
    local src = playerId
    local xPlayer = ESX.GetPlayerFromId(src)

    if MSK.TableContains(Config.AdminGroups, xPlayer.group) then
        OnlineAdmins = OnlineAdmins - 1
    end

    TriggerClientEvent("msk_whitelist:refreshOnlineAdmin", src, OnlineAdmins > 0)
end)

RegisterNetEvent('esx:playerDropped', function(playerId, reason)
    if not Config.Admin.enable then return end
	local src = playerId
	local xPlayer = ESX.GetPlayerFromId(src)

	if MSK.TableContains(Config.AdminGroups, xPlayer.group) then
        OnlineAdmins = OnlineAdmins - 1
    end

    TriggerClientEvent("msk_whitelist:refreshOnlineAdmin", src, OnlineAdmins > 0)
end)

RegisterNetEvent('msk_whitelist:notifyAdmins', function(serverId)
    Config.Notification(source, Translation[Config.Locale]['bell_notify_player'])
    local xPlayers = ESX.GetExtendedPlayers()
    
    for k, xPlayer in pairs(xPlayers) do
        if MSK.TableContains(Config.AdminGroups, xPlayer.group) then
            Config.Notification(xPlayer.source, Translation[Config.Locale]['bell_notify_admins']:format(serverId))
        end
    end
end)

RegisterServerEvent('msk_whitelist:markertp', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    whitelistPlayer(nil, {source = src})
    sendDiscordLog(nil, xPlayer, true)
end)

RegisterServerEvent('msk_whitelist:banPlayer', function()
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)
    
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

ESX.RegisterCommand(Config.Commands.einreise, Config.AdminGroups, function(xPlayer, args, showError)
    local xTarget = args.player

    if not isPlayerNew(xTarget.source) then 
        return Config.Notification(xPlayer.source, Translation[Config.Locale]['isWhitelisted']:format(xTarget.source))
    end

    TriggerClientEvent('msk_whitelist:isNew', xTarget.source, false)
    TriggerClientEvent('msk_whitelist:einreise', xTarget.source, Config.Locations.einreise)
    
    Config.Notification(xTarget.source, Translation[Config.Locale]['welcome'])
    Config.Notification(xPlayer.source, Translation[Config.Locale]['admin_success']:format(xTarget.source))
    
    sendDiscordLog(xPlayer, xTarget)

    MySQL.update("UPDATE users SET isNew = 0 WHERE identifier = @identifier", {
        ['@identifier'] = xTarget.identifier
    })
  end, false, {help = Translation[Config.Locale]['einreise'], validate = true, arguments = {
	{name = 'player', help = 'PlayerID', type = 'player'},
}})

ESX.RegisterCommand(Config.Commands.ausreise.command, Config.AdminGroups, function(xPlayer, args, showError)
    local xTarget = args.player
    local ausreise = Config.Commands.ausreise

    if ausreise.teleport then
        TriggerClientEvent('msk_whitelist:einreise', xTarget.source, Config.Locations.player_back_in)
    end
    TriggerClientEvent('msk_whitelist:isNew', xTarget.source, true)

    if ausreise.clear_inventory then
        for k, v in pairs(xTarget.inventory) do
            if v.count > 0 then
                xTarget.setInventoryItem(v.name, 0)
            end
        end
    end
    
    if ausreise.clear_weapons then
        for k, v in pairs(xTarget.loadout) do 
            xTarget.removeWeapon(v.name)
        end
    end

    if ausreise.clear_money then
        local esxConfig = ESX.GetConfig()
        xTarget.setAccountMoney('money', esxConfig.StartingAccountMoney.money or 0)
        xTarget.setAccountMoney('bank', esxConfig.StartingAccountMoney.bank or 0)
        xTarget.setAccountMoney('black_money', esxConfig.StartingAccountMoney.black_money or 0)
    end

    Config.Notification(xTarget.source, Translation[Config.Locale]['bye'])
    Config.Notification(xPlayer.source, Translation[Config.Locale]['admin_success_ausreise']:format(xTarget.source))

    sendDiscordLog(xPlayer, xTarget, 'ausreise')

    MySQL.update("UPDATE users SET isNew = 1 WHERE identifier = @identifier", {
        ['@identifier'] = xTarget.identifier
    })
    
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
  end, false, {help = Translation[Config.Locale]['ausreise'], validate = true, arguments = {
	{name = 'player', help = 'PlayerID', type = 'player'},
}})

RegisterCommand(Config.Commands.admin_inside, function(source, args, rawCommand)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if not MSK.TableContains(Config.AdminGroups, xPlayer.group) then
        return Config.Notification(xPlayer.source, Translation[Config.Locale]['no_rights'])
    end

    if not args[1] then args[1] = src end
    local xTarget = ESX.GetPlayerFromId(args[1])

    if Config.Locations.admin_outside:match('last_position') then 
        LastPosition[xTarget.source] = xTarget.getCoords(true)
    end

    TriggerClientEvent('msk_whitelist:einreise', xTarget.source, Config.Locations.admin_inside)
    TriggerClientEvent('msk_whitelist:toggleNametags', xTarget.source, true)
    TriggerClientEvent('msk_whitelist:setClothing', xTarget.source, true)
    Config.Notification(xTarget.source, Translation[Config.Locale]['rein'])
end)

RegisterCommand(Config.Commands.admin_outside, function(source, args, rawCommand)
    local src = source
    local xPlayer = ESX.GetPlayerFromId(src)

    if not MSK.TableContains(Config.AdminGroups, xPlayer.group) then
        return Config.Notification(xPlayer.source, Translation[Config.Locale]['no_rights'])
    end

    if not args[1] then args[1] = src end
    local xTarget = ESX.GetPlayerFromId(args[1])

    if Config.Locations.admin_outside:match('last_position') then 
        TriggerClientEvent('msk_whitelist:einreise', xTarget.source, LastPosition[xTarget.source])
        LastPosition[xTarget.source] = nil
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