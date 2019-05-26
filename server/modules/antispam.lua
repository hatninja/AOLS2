--Filters spam. Including lag messages.
local process = ...

local antispam = {}

function antispam:init()
	process:registerCallback(self,"ooc",3.9,self.handle)
	process:registerCallback(self,"emote",5,self.handle)
	process:registerCallback(self,"emote",0,self.trackemote)

	process:registerCallback(self,"music_play",5,self.music)

	process:registerCallback(self,"ooc",0,self.strike)
	process:registerCallback(self,"emote",0,self.strike)
	process:registerCallback(self,"command",0,self.strike)
	process:registerCallback(self,"music_play",0,self.strike)
	process:registerCallback(self,"event_play",0,self.strike)
	process:registerCallback(self,"call_mod",0,self.strike)
	process:registerCallback(self,"player_move",0,self.strike)
	process:registerCallback(self,"item_add", 0,self.strike)
	process:registerCallback(self,"item_edit", 0,self.strike)

	process:registerCallback(self,"player_update",0,self.cooldown)

	process:registerCallback(self,"item_add", 1,self.item)
	process:registerCallback(self,"item_edit", 1,self.item)
end

function antispam:handle(client, emote)
	local message = emote.dialogue or emote.message

	if emote.dialogue and config.IClock and not client.name then
		process:sendMessage(client,"Please use the OOC to unlock in-character messaging.")
		return true
	end

	if message == client.lastmsg then return true end
	if message and #message == 0 then return true end

	if message then
		if #message > config.maxmsglength then
			process:sendMessage(client,"Your message is "..tostring(#message - config.maxmsglength).." characters too long.")
			return true
		end
	end
	if emote.name and #emote.name > config.maxnamelength then
		process:sendMessage(client,"Your name is "..tostring(#emote.name - config.maxnamelength).." characters too long.")
		return true
	end
end
function antispam:trackemote(client, emote)
	client.lastmsg = message
end

function antispam:music(client,music)
	if music.track == "." then
		return true
	end
end

function antispam:strike(client,event)
	if type(event) == "table" and event.event == "hp" then return end
	if not client.spam then client.spam = 0 end

	client.spam = client.spam + 1/3

	--self:print("["..client.id.."] struck!\t"..client.spam)

	if client.spam > 1 then
		client.socket:close()
		self:print("["..client.id.."] sent too many messages at once!")
		return true
	end
end

function antispam:cooldown(client)
	if not client.spam then client.spam = 0 end
	client.spam = math.max(client.spam - (1/6)*config.rate,0)
end

function antispam:item(client,a,b)
	local item = tonumber(a) and b or a
	if #item.name > config.maxnamelength then
		process:sendMessage(client,"Evidence name is "..tostring(#item.name - config.maxnamelength ).." characters too long.")
		return true
	end
	if item.description and #item.description > config.maxmsglength then
		process:sendMessage(client,"Evidence description is "..tostring(#item.description - config.maxmsglength).." characters too long.")
		return true
	end
	if client.room
	and client.room.evidence
	and #client.room.evidence > config.maxevidence then
		process:sendMessage(client,"Too much evidence! You cannot add any more.")
		return true
	end
end

return antispam