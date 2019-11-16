local process = ...

local rooms = {
	name = "Rooms",

	help = {
		{"areainfo","[id]","Shows info about your current room.","Aliases: '/roominfo', '/ai', '/ri'"},
	}
}

function rooms:init()
	self.parent = process.modules["rooms"]

	process:registerCallback(self,"emote",0,function(self,client,emote)
		self:print(string.format("[%s] %s %s: %s",
			client.room and client.room.name,
			"["..tostring(client.id).."] "..(client.showname or ""),
			"("..tostring(client.character)..")",
			emote.dialogue))
	end)
	process:registerCallback(self,"ooc",0,function(self,client,ooc)
		self:print(string.format("[%s] %s: %s",  client.room and client.room.name, ooc.name, ooc.message))
	end)


	process:registerCallback(self,"player_done", 3,self.connected)
	process:registerCallback(self,"player_move", 3,self.welcometoroom)
	process:registerCallback(self,"player_leave", 3,self.disconnected)
	process:registerCallback(self,"command", 3,self.command)
end

function rooms:welcometoroom(client,room)
	process:sendBG(client,room.bg)
	process:sendMessage(room,client:getIdent().." joined this room.")

	if client.room then
		process:sendMessage(client.room,client:getIdent().." left to "..tostring(room.name)..".")
	end
end

function rooms:command(client, cmd,str,args)
	if not self.parent then return end
	if cmd == "areainfo" or cmd == "roominfo" or cmd == "ai" or cmd == "ri" then

		local id = args[1]
		if not id then
			for k,v in pairs(self.parent.rooms) do
				if k == id or k == tonumber(id) then
					id = k
					break
				end
			end
		end
		local room = self.parent.rooms[id] or client.room
		if not room then
			process:sendMessage(client,"Couldn't find area with that ID!")
			return true
		end
		local msg = "~~Area Info~~"
		msg=msg.."\nName: '"..tostring(room.name).."'"
		if room.basename and room.basename ~= room.name then
			msg=msg.." (Renamed)"
			msg=msg.."\nOriginal Name: '"..room.basename.."'"
		end
		msg=msg.."\nDescription: '"..tostring(room.desc).."'"
		msg=msg.."\nPlayers: "..tostring(room.count)
		msg=msg.."\nStatus: "..tostring(room.status)
		msg=msg.."\nBackground: '"..tostring(room.bg).."'"
		msg=msg.."\nMusic: '"..tostring(room.music).."'"
		if client.room == room and room.lock then
			msg=msg.."\nPasscode: '"..tostring(room.lock).."'"
		end
		if room.iniswap then
			msg=msg.."\nIniswap: Allowed"
		end
		if room.modlock then
			msg=msg.."\nLocked for Moderators."
		end

		process:sendMessage(client,msg)
		return true
	end
end

function rooms:connected(client)
	local msg = client:getIdent().." connected to the server."

	process:sendMessage(client.room,msg)
end

function rooms:disconnected(client)
	local msg = client:getIdent().." disconnected."

	if client.room then
		process:sendMessage(client.room,msg)
	end
end

return rooms
