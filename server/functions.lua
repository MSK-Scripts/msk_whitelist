isPlayerNew = function(playerId)
    if not playerId then return end    
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return false end
    local data = MySQL.query.await("SELECT * FROM users WHERE identifier = @identifier", {['@identifier'] = xPlayer.identifier})

    if data[1] and (data[1].isNew == '1' or data[1].isNew == 1) then
        return true
    end
    return false
end
exports('isPlayerNew', isPlayerNew)

whitelistPlayer = function(playerId, player)
    if not playerId then return end
    if not player then return end

    local xPlayer = nil
    if playerId then 
        xPlayer = ESX.GetPlayerFromId(playerId)
    end

    local xTarget = nil    
    if player.source then
        xTarget = ESX.GetPlayerFromId(player.source)
    elseif player.identifier then
        xTarget = ESX.GetPlayerFromIdentifier(player.identifier)
    elseif player.player then
        xTarget = player.player
    end

    if not isPlayerNew(xTarget.source) then 
        if xPlayer then
            Config.Notification(playerId, Translation[Config.Locale]['isWhitelisted']:format(xTarget.source))
        else
            logging('info', Translation[Config.Locale]['admin_success']:format(xTarget.source))
        end
        return 
    end

    TriggerClientEvent('msk_whitelist:isNew', xTarget.source, false)
    TriggerClientEvent('msk_whitelist:einreise', xTarget.source, Config.Locations.einreise)

    Config.Notification(xTarget.source, Translation[Config.Locale]['welcome'])
    if xPlayer then 
        Config.Notification(xPlayer.source, Translation[Config.Locale]['admin_success']:format(xTarget.source))
    else
        logging('info', Translation[Config.Locale]['admin_success']:format(xTarget.source))
    end

    sendDiscordLog(xPlayer, xTarget)

    MySQL.update("UPDATE users SET isNew = 0 WHERE identifier = @identifier", {
        ['@identifier'] = xTarget.identifier
    })
end
exports('whitelistPlayer', whitelistPlayer)

logging = function(code, ...)
    if not Config.Debug then return end
    MSK.Logging(code, ...)
end