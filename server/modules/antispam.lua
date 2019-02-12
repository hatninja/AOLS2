--Filters spam. Including lag messages.
local process = ...

local antispam = {}

function antispam:init()
	process:registerCallback(self,"ooc",5,self.handle)
	process:registerCallback(self,"emote",5,self.handle)

	process:registerCallback(self,"ooc",0,self.strike)
	process:registerCallback(self,"emote",0,self.strike)
	process:registerCallback(self,"music_play",0,self.strike)
	process:registerCallback(self,"event_play",0,self.strike)

	process:registerCallback(self,"player_update",0,self.cooldown)
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

function antispam:strike(client,event)
	if event and event.event == "hp" then return end
	if not client.spam then client.spam = 0 end

	client.spam = client.spam + 1/3

	--self:print("["..client.id.."] struck!\t"..client.spam)

	if client.spam > 1 then
		client.socket:close()
		self:print("["..client.id.."] sent too many messages at once!")
	end
end

function antispam:cooldown(client)
	if not client.spam then client.spam = 0 end
	client.spam = math.max(client.spam - (1/4)*config.rate,0)
end

return antispam