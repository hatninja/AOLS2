--Spectator handling.
local process = ...

local spectator = {}

function spectator:init()
	self.parent = process.modules["rooms"]

	process:registerCallback(self,"emote", 4,self.handle)
	process:registerCallback(self,"music_play", 4,self.handle)
	process:registerCallback(self,"event_play", 4,self.handle)
end

function spectator:handle(client)
	if not client.character or client.character == -1 then
		process:sendMessage(client, "Please select a character to use this feature!")
		return true
	end
end

return spectator