--Handles CMs.Additionally has casing mode features.
local process = ...

local rooms = {
	name = "CM",

	help = {
		{"cm","(user_id), (user_id 2), ...","Set a user as CM."},
	}
}

function rooms:init()
	self.parent = process.modules["rooms"]

	process:registerEvent("room_lock")

	process:registerCallback(self,"command", 3,self.command)
end


function rooms:command(client, cmd,str,args)
	if cmd == "cm" then
		local id = tonumber(args[1])
		local name = not id and str
		local player
		if id then
			player = process:getPlayer(id)
		else
			player = client
		end

		if player and player.room then
			local room = client.room
			if not room.cm and client == room.cm and client == player then
				room.cm = player
				process:sendMessage(room,client:getIdent().." became the room's CM!")
			end
			if not room.cm or (client == room.cm and client ~= player) then
				room.cm = player
				process:sendMessage(room,client:getIdent().." set the CM of the room to ["..tostring(player.id).."]!")
			end
			if client == room.cm then
				room.cm = nil
				process:sendMessage(room,client:getIdent().." reset the room's CM!")
			end
		end
		return true
	end
end

return rooms
