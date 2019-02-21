local process = ...

local Music = dofile(path.."server/classes/music.lua")

local rooms = {
	name = "Rooms",

	help = {
		{"areas","","Shows list of areas."},
		{"area","(id)","Move to an area."},
	}
}

function rooms:init()
	self.parent = process.modules["rooms"]

	process:registerCallback(self,"command", 3,self.command)
	process:registerCallback(self,"music_play", 3,self.areabutton)
	process:registerCallback(self,"player_move", 3,self.welcometoroom)

	self.roomlist = {}
	for k,room in pairs(self.parent.rooms) do
		if not room.hidden then
			local track = Music:new(room.name,0)
			track.room = room
			table.insert(self.roomlist, track)
		end
	end

	for i=#self.roomlist,1,-1 do
		table.insert(process.music, 1, self.roomlist[i])
	end
end

function rooms:areabutton(client, music)
	for i,v in ipairs(self.roomlist) do
		if v.name == music.track then
			if v.room then
				self.parent:moveto(client,v.room)
			end
			return true
		end
	end
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
			if target == client.room then return true end

			self.parent:moveto(client,target)

		else
			process:sendMessage(client,"I couldn't find a room with that ID!")
		end
		return true
	end
end

function rooms:welcometoroom(client,room)
	local msg = "~~"..room.name.."~~"
	if room.desc then
		msg = msg .."\n"..room.desc
	end
	process:sendMessage(client,msg)
	
	process:sendEmote(client,{
		dialogue="}}"..tostring(room.name),
		name=">",
		side=client.side or SIDE_WIT,
	})
end

return rooms