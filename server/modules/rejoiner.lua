--Rejoiner, helps disconnected players rejoin and replace ghosts.
local process = ...
local misc = {
	help = {
		{"rejoin","","Reconnects you as your ghost player if it exists on the server."},
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
			and client.ip == player.ip then
				ghost = player
				break
			end
		end
		if ghost then
			process:sendMessage(client,"Ghost found, rejoining.")

			ghost.socket, client.socket = client.socket, ghost.socket
			client:close()

			ghost:send("CHAR_PICK",{character=ghost.character})

			local room = ghost.room
			if rooms then rooms:joinroom(ghost, ghost.room) end
		else
			process:sendMessage(client,"Could not find a ghost to rejoin as!")
		end
		return true
	end
end

return misc
