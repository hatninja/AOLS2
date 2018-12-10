local process = ...

local rooms = {
	name = "Rooms"
}

function rooms:init()
	self.parent = process.modules["rooms"]

	process:registerCallback(self,"command", 3,self.command)
end

function rooms:command(client, cmd,str,args)
	if cmd == "areas" then
		local msg = "~~Area List~~"

		for k,room in pairs(self.parent.rooms) do
			if not room.hidden or room == client.room then
				msg=msg.."\n"
				if room == client.room then
					msg=msg.."> "
				elseif tonumber(k) then
					msg=msg..tostring(k)..": "
				end
				msg=msg..room.name
				if room.status then
					msg=msg.."["..room.status.."]"
				end
				msg=msg.." ("..tostring(room.count)..")"
			end
		end

		process:sendMessage(client,msg)
		return true
	end

	if cmd == "area" then
		if str == "" then self:command(client, "areas",str,args);return true end 

		local target
		for k,room in pairs(self.parent.rooms) do
			local key = k
			key = tonumber(k) or key

			if tonumber(args[1]) == key then
				target = room
				break
			end
		end

		if target then
			self.parent:moveto(client,target)
			process:sendMessage(client,"~~"..target.name.."~~")
		else
			process:sendMessage(client,"I couldn't find a room with that ID!")
		end
		return true
	end
end

return rooms