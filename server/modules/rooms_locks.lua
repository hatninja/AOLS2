--Handles room locking.
local process = ...

local rooms = {
	name = "Rooms",

	help = {
		{"lock","[pass]","Locks your room with a passcode."},
		{"key","(pass)","Sets your key. Allows you to enter rooms with the same passcode."},
	}
}

function rooms:init()
	self.parent = process.modules["rooms"]

	process:registerEvent("room_lock")

	process:registerCallback(self,"command", 3,self.command)
	process:registerCallback(self,"player_move", 4,self.move)
	process:registerCallback(self,"player_leave", 4,self.leave)
end


function rooms:command(client, cmd,str,args)
	if cmd == "lock" then
		local room = client.room
		if room and process:event("room_lock",client,room,args[1]) then
			if args[1] then
				room.lock = args[1]
				process:sendMessage(room,client:getIdent().." locked the room with passcode '"..room.lock.."'")
			else
				room.lock = nil
				process:sendMessage(room,client:getIdent().." removed the room's lock.")
			end
		end
		return true
	end
	if cmd == "key" then
		if args[1] then
			client.key = args[1]
			process:sendMessage(client,"Key set to '"..args[1].."'")
		else
			process:sendMessage(client,"Please enter a passcode to use as a key!")
		end
		return true
	end
	if cmd == "modlock" then
		local room = client.room
		if room and client.mod then
			room.modlock = not room.modlock
			if room.modlock then
				process:sendMessage(client,"Room is now mod-locked.")
			else
				process:sendMessage(client,"Room is no longer mod-locked.")
			end
			process:event("room_lock",room)
			return true
		end
	end
	if cmd == "cm" then
		local id = tonumber(args[1])
		local name = not id and str
		local player
		if id then
			player = process:getPlayer(id)
		else
			player = client
		end

		if player.room then
			local room = client.room
			if not room.cm or client == room.cm then
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

function rooms:move(client, targetroom, room)
	if targetroom.lock and targetroom.lock ~= client.key then
		process:sendMessage(client,"Cannot enter! Please enter with the right passcode via /key")
		return true
	end
	if targetroom.modlock and not client.mod then
		process:sendMessage(client,"This room is for moderators only!")
		return true
	end

	if room and room.count == 0 then
		room.lock = nil
		process:event("room_lock",room)
	end
end

function rooms:leave(client)
	local room = client.room
	if room and room.count == 0 then
		room.lock = nil
		process:event("room_lock",room)
	end
end

return rooms
