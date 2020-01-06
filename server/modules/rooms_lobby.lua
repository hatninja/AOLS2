--Module for the "lobby" room type.
local process = ...

local lobby = {
	name = "Lobbies"
}

function lobby:init()
	self.parent = process.modules["rooms"]

	process:registerCallback(self,"room_make", 3,self.make)

	process:registerCallback(self,"room_bg", 3,self.bg_block)
	process:registerCallback(self,"room_doc", 3,self.doc_block)
	process:registerCallback(self,"room_status", 3,self.status_block)
	process:registerCallback(self,"room_lock", 3,self.lock_block)

	process:registerCallback(self,"event_play", 3,self.block)
	process:registerCallback(self,"item_add", 3,self.block)
	process:registerCallback(self,"item_edit", 3,self.block)
	process:registerCallback(self,"item_remove", 3,self.block)
end

function lobby:make(room)
	room.hp = room.hp or {0,0}
end

function lobby:block(client, event)
	if client.room and client.room.kind == "lobby" and not client.mod then return true end
end

function lobby:bg_block(client,room,bg)
	if (client.room and client.room.kind ~= "lobby") or client.mod then return end
	process:sendMessage(client,"You cannot change the background in this room!")
	return true
end
function lobby:doc_block(client,room,doc)
	if (client.room and client.room.kind ~= "lobby") or client.mod then return end
	process:sendMessage(client,"You cannot change the doc in this room!")
	return true
end
function lobby:status_block(client,room,doc)
	if (client.room and client.room.kind ~= "lobby") or client.mod then return end
	process:sendMessage(client,"You cannot change the status in this room!")
	return true
end
function lobby:lock_block(client,room,doc)
	if (client.room and client.room.kind ~= "lobby") or client.mod then return end
	process:sendMessage(client,"You cannot change the lock in this room!")
	return true
end

function lobby:command(client, cmd,str,args)
	if (client.room and client.room.kind ~= "lobby") or client.mod then return end
end


return lobby
