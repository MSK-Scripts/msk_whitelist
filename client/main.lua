-- Restores the character's look after leaving admin mode.
--
-- Which resource owns the appearance differs per server, and the ESX pairing of
-- esx_skin and skinchanger only exists on ESX. The one that is actually running
-- is used, and when none of them is, the step is skipped rather than failing:
-- nothing changed the appearance in that case either.
local function restoreAppearance()
    if GetResourceState('illenium-appearance') == 'started' then
        return exports['illenium-appearance']:reloadPedSkin()
    end

    if GetResourceState('qb-clothing') == 'started' then
        return TriggerServerEvent('qb-clothes:loadPlayerSkin')
    end

    if GetResourceState('esx_skin') == 'started' and GetResourceState('skinchanger') == 'started' then
        -- esx_skin answers through ESX's own callback system, which MSK.Trigger
        -- does not reach, so ESX is fetched here. This branch is only ever
        -- reached on a server that actually runs esx_skin.
        local ok, core = pcall(function() return exports['es_extended']:getSharedObject() end)
        if not ok or not core then return end

        core.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
            if skin then
                TriggerEvent('skinchanger:loadSkin', skin)
            end
        end)
    end
end

local isNewPlayer, nametags, isAdminOnline = false, false, false
local playerGamerTags = {}

AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() ~= resource then return end
    isNewPlayer = isPlayerNew()
end)

RegisterNetEvent("msk_whitelist:isNew", function(data)
    isNewPlayer = data
end)

RegisterNetEvent("msk_whitelist:refreshOnlineAdmin", function(data)
    isAdminOnline = data
end)

RegisterNetEvent("msk_whitelist:einreise", function(coords)
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, true)
end)

RegisterNetEvent("msk_whitelist:toggleNametags", function(bool)
    if Config.NameTags.enable then
        nametags = bool

        if not nametags then
            cleanUpGamerTags()
        end
    end
end)

RegisterNetEvent("msk_whitelist:setClothing", function(duty)
    TriggerEvent('skinchanger:getSkin', function(skin)
        if duty then
            local uniform

            if skin.sex == 0 then -- male
                uniform = Config.Clothing.male
            else -- female
                uniform = Config.Clothing.female
            end

            if uniform then
                TriggerEvent('skinchanger:loadClothes', skin, uniform)

                local playerPed = PlayerPedId()
                if Config.AdminProtection.setArmor then SetPedArmour(playerPed, Config.AdminProtection.setArmor) end
                if Config.AdminProtection.setGodmode then 
                    SetPlayerInvincible(PlayerId(), true) 
                    SetEntityProofs(playerPed, true, true, true, true, true, true, true, true)
                end
                if Config.AdminProtection.disableCanRagdoll then SetPedCanRagdoll(playerPed, false) end
                if Config.AdminProtection.disableCanBeDamaged then SetEntityCanBeDamaged(playerPed, false) end
            end
        else
            restoreAppearance()
            
            local playerPed = PlayerPedId()
            if Config.AdminProtection.setArmor then SetPedArmour(playerPed, 0) end
            if Config.AdminProtection.setGodmode then 
                SetPlayerInvincible(PlayerId(), false) 
                SetEntityProofs(playerPed, false, false, false, false, false, false, false, false)
            end
            if Config.AdminProtection.disableCanRagdoll then SetPedCanRagdoll(playerPed, true) end
            if Config.AdminProtection.disableCanBeDamaged then SetEntityCanBeDamaged(playerPed, true) end
        end
    end)
end)

CreateThread(function()
    TriggerEvent('chat:addSuggestion', '/' .. Config.Commands.admin_inside, Translation[Config.Locale]['admin_inside'], {
        { name = "playerId", help = "PlayerId [Optional]" },
    })

    TriggerEvent('chat:addSuggestion', '/' .. Config.Commands.admin_outside, Translation[Config.Locale]['admin_outside'], {
        { name = "playerId", help = "PlayerId [Optional]" },
    })
end)

function cleanUpGamerTags()
    for _, v in pairs(playerGamerTags) do
        if IsMpGamerTagActive(v.gamerTag) then
            RemoveMpGamerTag(v.gamerTag)
        end
    end
    playerGamerTags = {}
end

CreateThread(function()
    while true do
        local sleep = 250

        if MSK.IsPlayerLoaded() and isNewPlayer then
            local playerPed = PlayerPedId()
            local coords = Config.Locations.player_back_in
            local distance = #(GetEntityCoords(playerPed) - coords)
                
            if distance >= Config.TPBackDistance then
                SetEntityCoords(playerPed, coords.x, coords.y, coords.z, false, false, false, true)
                Wait(500)
                TriggerServerEvent('msk_whitelist:banPlayer')
            end
        end

        Wait(sleep)
    end
end)

if Config.NameTags.enable then
    CreateThread(function()
        while true do
            local sleep = 250

            if nametags then
                local targetPlayers = GetActivePlayers()

                for k, v in ipairs(targetPlayers) do
                    local targetPed = GetPlayerPed(v)
                    local gamerTagString = '[' .. GetPlayerServerId(v) .. ']' .. ' ' .. GetPlayerName(v)

                    if PlayerPedId() ~= targetPed or Config.NameTags.showOwnID then
                        if not playerGamerTags[v] or not IsMpGamerTagActive(playerGamerTags[v].gamerTag) then
                            playerGamerTags[v] = {
                                gamerTag = CreateFakeMpGamerTag(targetPed, gamerTagString, false, false, 0),
                                ped = targetPed
                            }
                        end

                        local targetTag = playerGamerTags[v].gamerTag
                        local dist = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(targetPed))

                        if dist <= Config.NameTags.distance then
                            SetMpGamerTagVisibility(targetTag, 0, 1)

                            if Config.NameTags.showHealth then
                                SetMpGamerTagHealthBarColor(targetTag, 129)
                                SetMpGamerTagAlpha(targetTag, 2, 255)
                                SetMpGamerTagVisibility(targetTag, 2, 1)
                            end
                        else
                            SetMpGamerTagVisibility(targetTag, 0, 0)

                            if Config.NameTags.showHealth then
                                SetMpGamerTagVisibility(targetTag, 2, 0)
                            end
                        end
                    end
                end
            end

            Wait(sleep)
        end
    end)
end

if Config.Locations.bell.enable then
    local belled = false

    CreateThread(function()
        while true do
            local sleep = 250
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local distance = #(playerCoords - Config.Locations.bell.location)

            if distance <= Config.Locations.bell.distance then
                sleep = 0
                MSK.Draw3DText(Config.Locations.bell.location, Translation[Config.Locale]['bell_3dtext'], Config.Locations.bell.size)

                if IsControlJustPressed(0, Config.Marker.hotkey) then
                    if not belled then
                        belled = true
                        TriggerServerEvent('msk_whitelist:notifyAdmins', GetPlayerServerId(PlayerId()))

                        local timeout = MSK.AddTimeout(Config.Locations.bell.timeout * 1000, function()
                            belled = false
                        end)
                    else
                        Config.Notification(nil, 'You already pressed the Bell!')
                    end
                end
            end

            Wait(sleep)
        end
    end)
end

local marker = Config.Marker
local admin = Config.Admin
CreateThread(function()
    while true do
        local sleep = 250
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        if not admin.enable or (admin.enable and not isAdminOnline and admin.enableMarker) then
            if marker.enable then
                for k, coords in pairs (marker.coords) do
                    local distance = #(playerCoords - coords)
                    
                    if distance <= marker.distance then
                        sleep = 0
                        DrawMarker(marker.type, coords.x, coords.y, coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, marker.size.a, marker.size.b, marker.size.c, marker.color.a, marker.color.b, marker.color.c, 100, false, true, 0, false)
                    end

                    if marker.text3d.enable and distance <= marker.distance then
                        sleep = 0
                        MSK.Draw3DText(coords, marker.text3d.string, marker.text3d.size)
                    end

                    if distance <= 2.0 then
                        sleep = 0
                        if IsControlJustPressed(0, marker.hotkey) then
                            TriggerServerEvent('msk_whitelist:markertp')
                        end
                    end
                end
            end
        end

        if admin.enable and isAdminOnline then
            for k, coords in pairs (admin.text3d.coords) do
                local distance = #(playerCoords - coords)

                if admin.text3d.enable and distance <= admin.text3d.distance then
                    sleep = 0
                    MSK.Draw3DText(coords, admin.text3d.string_adminOnline, admin.text3d.size)
                end
            end
        elseif admin.enable and not isAdminOnline then
            for k, coords in pairs (admin.text3d.coords) do
                local distance = #(playerCoords - coords)

                if admin.text3d.enable and distance <= admin.text3d.distance then
                    sleep = 0
                    MSK.Draw3DText(coords, admin.text3d.string_adminOffline, admin.text3d.size)
                end
            end
        end

        Wait(sleep)
    end
end)

isPlayerNew = function(playerId)
    if not playerId then
        return isNewPlayer
    end
    return MSK.Trigger('msk_whitelist:getPlayerIsNew', playerId)
end
exports('isPlayerNew', isPlayerNew)

logging = function(code, ...)
    if not Config.Debug then return end
    MSK.Logging(code, ...)
end