--Rejoiner, helps disconnected players rejoin and replace ghosts.
local process = ...
local misc = {
	help = {
		{"rejoin","","Reconnects you as your ghost."},
	}
}

function misc:init(process)
	process:registerCallback(self,"command",3,self.command)
end

function misc:command(client, cmd,str,args)
	if cmd == "rejoin" then
		local rooms = process.modules["rooms"]

		local ghost
		for player in process:eachPlayer() do
			if client ~= player
			and client.hardwareid == player.hardwareid
			and client.ip == player.ip then
				ghost = player
				break
			end
		end
		if ghost then
			process:sendMessage(client,"Ghost found, rejoining.")

			ghost.socket, client.socket = client.socket, ghost.socket
			client.socket:close()

			local room = ghost.room
			if rooms then rooms:joinroom(ghost, ghost.room) end

			ghost:send("CHAR_PICK",{character=ghost.character})
		else
			process:sendMessage(client,"Could not find a ghost to rejoin as!")
		end
		return true
	end
end

return misc