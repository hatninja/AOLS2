--Filters spam. Including lag messages.
local process = ...

local antispam = {}

function antispam:init()
	process:registerCallback(self,"ooc",5,self.handle)
	process:registerCallback(self,"emote",5,self.handle)
end

function antispam:handle(client, emote)
	local message = emote.dialogue or emote.message

	if message == client.lastmsg then return true end

	if message and #message > config.maxmsglength then
		process:sendMessage(client,"Your message is "..tostring(config.maxmsglength - #message).." characters too long.")
		return true
	end
	if emote.name and #emote.name > config.maxnamelength then
		process:sendMessage(client,"Your name is "..tostring(config.maxnamelength - #emote.name).." characters too long.")
		return true
	end

	client.lastmsg = message
end

return antispam