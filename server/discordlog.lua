-- Insert you Discord Webhook here
local webhookLink = ""

sendDiscordLog = function(xPlayer, tPlayer, desc)
	if desc then
		if type(desc) == 'string' and desc:match('ausreise') then 
			desc = Translation[Config.Locale]['dc_ausreise']:format(GetPlayerName(xPlayer.source), xPlayer.source, GetPlayerName(tPlayer.source), tPlayer.source)
		else
			desc = Translation[Config.Locale]['dc_entry_self']:format(GetPlayerName(tPlayer.source), tPlayer.source)
		end
	else
		desc = Translation[Config.Locale]['dc_entry']:format(GetPlayerName(xPlayer.source), xPlayer.source, GetPlayerName(tPlayer.source), tPlayer.source)
	end

	local fields
	if xPlayer then
		fields = {
			{name = "Admin", value = GetPlayerName(xPlayer.source), inline = true},
			{name = "Player", value = GetPlayerName(tPlayer.source), inline = true},
		}
	else
		fields = {
			{name = "Player", value = GetPlayerName(tPlayer.source), inline = true},
		}
	end

	if Config.DiscordLog then
		local botColor = Config.botColor
		local botName = Config.botName
		local botAvatar = Config.botAvatar
		local title = "MSK Whitelist"
		local description = desc
		local fields = fields
		local footer = {
			text = "© MSK Scripts", 
			link = "https://i.imgur.com/PizJGsh.png"
		}
		local time = "%d/%m/%Y %H:%M:%S" -- format: "day/month/year hour:minute:second"

		MSK.AddWebhook(webhookLink, botColor, botName, botAvatar, title, description, fields, footer, time)
	end
end