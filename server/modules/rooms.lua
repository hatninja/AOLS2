local process = ...

local rooms = {
	name = "Rooms"
}

function rooms:reload()
	self.rooms = {}
	self.defaultroom = dofile(path.."config/rooms.lua")(self.rooms)

	for k,room in pairs(self.rooms) do
		room.name = room.name or k
		room.kind = room.kind or "court"
		room.music = room.music or "No Music"
		room.bg = room.bg or "gs4"
		room.hp = room.hp or {0,0}
		room.evidence = room.evidence or {}

		room.players = {}
		room.count = 0

		process:event("room_make",room)
	end
	
	for player in process:eachPlayer() do
		self:joinroom(client,self.defaultroom)
	end

	self:print("Reloaded all rooms.")
end

function rooms:init()
	self:reload()

	process:registerCallback(self,"emote",0,function(self,client,emote)
		self:print(string.format("%s %s: %s",client.name or "Player["..client.id.."]", emote.name or client.character,emote.dialogue))
	end)

	--The events to block based on room locations.
	local roomchecks = {"emote_received","ooc_received","music_received","event_received"}
	for i,v in ipairs(roomchecks) do
		process:registerCallback(self,v, 4,self.roomcheck)
	end

	process:registerCallback(self,"player_join", 3,self.joinroom) --Change to player_done once it's implemented.
	process:registerCallback(self,"player_leave", 3,self.leaveroom)
end

function rooms:roomcheck(sender, receiver, data)
	if sender.id ~= -1 and not data.global and sender.room ~= receiver.room then
		return true
	end
end

function rooms:joinroom(client,r)
	local room = r or self.defaultroom
	room.players[client] = client
	room.count = room.count + 1
	client.room = room

	self:print("Player["..client.id.."] joined room: "..room.name)

	client:send("BG",{bg=room.bg})
	client:send("MUSIC",{track=room.music})
end
function rooms:leaveroom(client)
	local room = client.room
	if room then
		room.players[client] = nil
		room.count = room.count - 1
	end
end

function rooms:moveto(client,targetroom)
	if process:event("player_move", client, targetroom, client.room) then
		self:leaveroom(client)
		self:joinroom(client,targetroom)
	end
end

return rooms