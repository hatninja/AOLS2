local process = ...

local rooms = {
	name = "Rooms"
}

function rooms:init()
	self.parent = process.modules["rooms"]
	
	process:registerCallback(self,"emote",0,function(self,client,emote)
		self:print(string.format("[%s] %s %s: %s",
			client.room and client.room.name,
			"["..tostring(client.id).."]"..(client.showname or ""),
			"("..tostring(client.character)..")",
			emote.dialogue))
	end)
	process:registerCallback(self,"ooc",0,function(self,client,ooc)
		self:print(string.format("[%s] %s: %s",  client.room and client.room.name, ooc.name, ooc.message))
	end)


	process:registerCallback(self,"player_done", 3,self.connected)
	process:registerCallback(self,"player_move", 3,self.welcometoroom)
	process:registerCallback(self,"player_leave", 3,self.disconnected)
end

function rooms:welcometoroom(client,room)
	process:sendBG(client,room.bg)
	process:sendMessage(room,"["..client.id.."] joined this room.")

	process:sendMessage(client.room,"["..client.id.."] left to "..tostring(room.name)..".")
end

function rooms:connected(client)
	local msg = "["..client.id.."] connected to the server."
	process:sendMessage(client.room,msg)
end

function rooms:disconnected(client)
	local msg = "["..client.id.."] disconnected."
	process:sendMessage(client.room,msg)
end

return rooms