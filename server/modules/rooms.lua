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
		room.hp = room.hp or room.kind ~= "lobby" and {10,10} or {0,0}
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

	process:registerCallback(self,"music_play",1,function(self,client,music) --Track last played music.
		if client.room then
			client.room.music = music.track
		end
	end)

	--The events to block based on room locations.
	local roomchecks = {"emote_received","ooc_received","music_received","event_received"}
	for i,v in ipairs(roomchecks) do
		process:registerCallback(self,v, 4,self.roomcheck)
	end

	process:registerCallback(self,"player_join", 5,self.joinroom)
	process:registerCallback(self,"player_leave", 1,self.leaveroom)
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

	process:sendMusic(client,room.music)
	process:sendBG(client,room.bg)
	client:send("EVENT",{event="hp",side=1,amount=room.hp[1]})
	client:send("EVENT",{event="hp",side=2,amount=room.hp[2]})
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