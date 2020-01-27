--Module for the "rp" room type.
local process = ...

local rp = {}

function rp:init()
	self.parent = process.modules["rooms"]

	process:registerCallback(self,"room_make", 3,self.make)

	process:registerCallback(self,"emote", 3,self.emote)
	process:registerCallback(self,"music_play", 3,self.music)
	process:registerCallback(self,"event_play", 3,self.event)
end

function rp:make(room)
	room.hp = {10,10} or room.hp
end

function rp:emote(client, emote)
end

function rp:music(client, music)
end

function rp:event(client, event)
	local room = client.room

	if not room or room.kind ~= "rp" then return end

	if event.event == "hp" then
		if not room.hp[event.side] then return end
		local change = event.change or (event.amount and event.amount - room.hp[event.side])
		room.hp[event.side] = math.min(math.max(room.hp[event.side] + change, 0), 10)
	end
end

return rp
