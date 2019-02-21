local process = ...

local whois = {

	help = {
		{"whois","(id)","Get player information."},
		{"getarea","","Gets list of people in a room."},
		{"getareas","","Gets a list of all people in areas."},
		{"getplayers","","Gets a list of all people."},
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

		if player then
			local msg = "~~Whois~~"
			msg=msg.."\nPlayer ID: "..tostring(player.id)
			msg=msg.."\nSoftware: "..tostring(player.software).." ("..tostring(player.version)..")"
			msg=msg.."\nUsername: "..tostring(player.name)

			if client.mod then
				msg=msg.."\nAddress: "..tostring(player.ip)..":"..tostring(player.port)
				msg=msg.."\nHardware: "..tostring(player.hardwareid)
			end

			msg=msg.."\nRoom: "..tostring(player.room and player.room.name)
			msg=msg.."\nCharacter: "..(player.character or "Spectator")
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

		local msg = ""
		if check == process then
			msg = msg.."~~Player List~~"
		else --A room object.
			msg = msg.."~~"..tostring(check.name).."~~"
		end
		for k,player in pairs(check.players) do
			msg=msg.."\n"..self:list(player)
		end

		process:sendMessage(client,msg)
		return true
	end
	if cmd == "getareas" then
		local rooms_module = process.modules["rooms"]
		if rooms_module then
			local msg = ""
			for k,room in pairs(rooms_module.rooms) do
				if not room.hidden and room.count > 0 then
					msg = msg.."~~"..tostring(room.name).."~~"
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
		local msg = "~~Player List~~"
		for player in process:eachPlayer() do
			msg=msg.."\n"..self:list(player)
		end
		msg=msg.."\n--"..process.playercount.." players total--"

		process:sendMessage(client,msg)
		return true
	end
end

function whois:list(player)
	local msg = ""
	msg=msg..tostring(player.name or "["..player.id.."]").." "..(player.character or "Spectator")
	msg=msg.." - "..process:getSideName(player.side)
	return msg
end

return whois