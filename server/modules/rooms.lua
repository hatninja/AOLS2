local process = ...

local rooms = {
	name = "Rooms",
	rooms = {},
}

local Room = require(path.."server/classes/room")

function rooms:reload()
	self.rooms = {}
	local id = dofile(path.."config/rooms.lua")(self.rooms)

	for k,room in pairs(self.rooms) do
		local newroom = Room:new(room, k)
		self.rooms[k] = newroom
		process:event("room_make",newroom)
	end

	self.defaultroom = self.rooms[id]
	assert(self.defaultroom,"Invalid default room ID.")

	for player in process:eachPlayer() do
		self:joinroom(client,self.defaultroom)
	end

	process:event("rooms_reload")

	self:print("Reloaded all rooms.")
end

function rooms:init()
	process:registerEvent("rooms_reload")
	process:registerEvent("player_move")
	process:registerEvent("room_make")

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

	process:registerCallback(self,"player_done", 5,self.joinroom)
	process:registerCallback(self,"player_leave", 1,self.leaveroom)

	process:registerCallback(self,"item_add", 4,self.item_add)
	process:registerCallback(self,"item_edit", 4,self.item_edit)
	process:registerCallback(self,"item_remove", 4,self.item_remove)
	process:registerCallback(self,"item_list", 4,self.item_list)

	process:registerCallback(self,"done", 5,self.done)
end

function rooms:done()
	self:reload()
end

function rooms:roomcheck(sender, receiver, data)
	if not data.global and sender.room ~= receiver.room then
		return true
	end
end

function rooms:joinroom(client,r)
	local room = r or self.defaultroom

	if client.room == room then return end

	room.players[client] = client
	room.count = room.count + 1
	client.room = room

	self:print(client:getIdent().." joined room: "..room.name)

	process:sendMusic(client,room.music)
	process:sendBG(client,room.bg)
	if room.hp then
		process:sendEvent(client,{event="hp",side=1,amount=room.hp[1]})
		process:sendEvent(client,{event="hp",side=2,amount=room.hp[2]})
	end
	process:sendItems(client,{})
end
function rooms:leaveroom(client)
	local room = client.room
	if room then
		room.players[client] = nil
		room.count = math.max(room.count - 1,0)
		client.room = nil
	end
end

function rooms:getRoom(id)
	return self.rooms[id]
end

function rooms:moveto(client,targetroom,override)
	if override
	or client.room ~= targetroom and process:event("player_move", client, targetroom, client.room) then
		self:leaveroom(client)
		self:joinroom(client,targetroom)
	end
end


function rooms:item_add(client,item)
	local room = client.room
	if room then
		table.insert(room.evidence,item)
	end
end
function rooms:item_edit(client,id,item)
	local room = client.room
	if room and tonumber(id) and room.evidence[id+1] then
		room.evidence[id+1] = item
	end
end
function rooms:item_remove(client,id)
	local room = client.room
	if room and tonumber(id) and room.evidence[id+1] then
		table.remove(room.evidence, id+1)
	end
end
function rooms:item_list(client,list)
	local room = client.room
	if room then
		for i,v in ipairs(room.evidence) do
			table.insert(list,v)
		end
	end
end

return rooms
