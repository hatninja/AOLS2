local process = ...

local whois = {

	help = {
		{"whois","[id]","Show information on a player."},
		{"getarea","[id]","Show the list of people in the room."},
		{"getareas","","Gets a list of all areas and players."},
		{"getplayers","","Gets a list of all the people on the server."},
	}
}

function whois:init()
	process:registerCallback(self,"command",3,self.command)
end

function whois:command(client, cmd,str,args)
	if cmd == "whois" then
		local id = tonumber(args[1])
		local name = not id and str
		local player
		if id then
			player = process:getPlayer(id)
		elseif str ~= "" then
			for p in process:eachPlayer() do
				if name == p.name then
					player = p
					break
				end
			end
		else
			player = client
		end

		--Uses variables from communication.lua
		if player then
			local msg = "~~Whois~~"
			msg=msg.."\nPlayer ID: "..tostring(player.id)
			msg=msg.."\nSoftware: "..tostring(player.software).." ("..tostring(player.version)..")"
			msg=msg.."\nNickname: "..(player.name and ("'"..tostring(player.name).."'") or "N/A")

			if player.showname then
				msg=msg.."\nShowname: '"..tostring(player.showname).."'"
			end
			if player.status then
				msg=msg.."\nStatus: '"..tostring(player.status).."'"
			end

			if player.mod then
				msg=msg.."\nModerator: Yes"
			end
			if client.mod then
				msg = msg.."\nIPID: "..tostring(player.ipid)
				--[[msg=msg.."\nAddress: "..tostring(player.ip)..":"..tostring(player.port)
				msg=msg.."\nHardware: "..tostring(player.hardwareid)]]
			end

			msg=msg.."\nRoom: "..tostring(player.room and player.room.name)
			msg=msg.."\nCharacter: "..(player.character or "Spectator")
			if player.iniswapped then msg=msg.."*" end
			msg=msg.."\nPosition: "..process:getSideName(player.side)
			process:sendMessage(client,msg)
		else
			process:sendMessage(client,"I couldn't find a player with that ID!")
		end
		return true
	end
	if cmd == "getarea" then
		local check = process
		if str == "" then
			if client.room then
				check = client.room
			end
		else
			local key = tonumber(args[1]) or str
			local rooms_module = process.modules["rooms"]
			local room = rooms_module and rooms_module.rooms[key]
			if room then
				check = room
			else
				process:sendMessage(client,"I couldn't find a room with that ID!")
				return true
			end
		end

		local msg = "Total players: "..tostring(check.count)
		msg = msg.."\n~~"..tostring(check.name).."~~"
		if check.players then
			for k,player in pairs(check.players) do
				msg=msg.."\n"..self:list(player)
			end
		end

		process:sendMessage(client,msg)
		return true
	end
	if cmd == "getareas" then
		local rooms_module = process:getModule("rooms")
		if rooms_module then
			local msg = "Total players: "..(process.playercount)
			for k,room in pairs(rooms_module.rooms) do
				if not (room.hidden and not client.mod) and room.count > 0 then
					msg = msg.."\n~~"..tostring(room.name).."~~"
					for k,player in pairs(room.players) do
						msg=msg.."\n"..self:list(player)
					end
				end
			end

			process:sendMessage(client,msg)
		else

			self:command(client,"getplayers",str,args)
		end
		return true
	end
	if cmd == "getplayers" then
		local msg = "Total players: "..(process.playercount).."\n~~Player List~~"
		for player in process:eachPlayer() do
			msg=msg.."\n"..self:list(player)
		end

		process:sendMessage(client,msg)
		return true
	end
end

function whois:list(player)
	local msg = ""
	msg=msg.. player:getIdent() .. (player.status and " - "..player.status or "")
	msg=msg.. "\n" ..(player.character or "Spectator")
	if player.iniswapped then msg=msg.."*" end
	msg=msg.. " - " ..process:getSideName(player.side)
	return msg
end

return whois
