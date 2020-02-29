local process = ...

local Music = require(path.."server/classes/music")

local rooms = {
	name = "Rooms",

	help = {
		{"areas","","Show a navigational list of all the areas.","IDs are listed with every area name.\n'/area' exists as a legacy shorthand."},
		{"area","(id)","Move to an area via it's corresponding ID.","The area list can be shown by providing no ID as an argument."},
	}
}

function rooms:init()
	self.parent = process.modules["rooms"]

	process:registerCallback(self,"command", 3,self.command)
	process:registerCallback(self,"music_play", 5,self.areabutton)
	process:registerCallback(self,"player_move", 1,self.welcometoroom)
	process:registerCallback(self,"player_done", 4,self.arealist)

	process:registerCallback(self,"done", 3,self.done)
	process:registerCallback(self,"rooms_reload", 3,self.done)
end

function rooms:done()
	self.roomlist = {}
	for k,room in pairs(self.parent.rooms) do
		if not room.hidden then
			local track = Music:new(room.name,0)
			track.room = room
			table.insert(self.roomlist, track)
		end
	end

	if self.buttons then
		for i=1,self.buttons do
			table.remove(process.music,1)
		end
	end
	self.buttons = 0

	for i=#self.roomlist,1,-1 do
		table.insert(process.music, 1, self.roomlist[i])

		--Count buttons for clean reload.
		self.buttons = self.buttons + 1
	end
end

function rooms:areabutton(client, music)
	for i,v in ipairs(self.roomlist) do
		if v.name == music.track then
			if v.room then
				self.parent:moveto(client, v.room)
			end
			return true
		end
	end
end

function rooms:command(client, cmd,str,args)
	if not self.parent then return end
	if cmd == "areas" then
		local msg = "~~Area List~~"

		for k,room in pairs(self.parent.rooms) do
			if not (room.hidden and not client.mod) or room == client.room then
				msg=msg.."\n"
				if room == client.room then
					msg=msg.."> "
				elseif tonumber(k) then
					msg=msg..tostring(k)..": "
				end
				msg=msg..room.name
				if room.status then
					msg=msg.." ["..room.status.."]"
				end
				if room.lock then
					msg=msg.." [Lock]"
				end
				if room.modlock then
					msg=msg.." [Mod]"
				end
				msg=msg.." ("..tostring(room.count)..")"
			end
		end

		process:sendMessage(client,msg)
		return true
	end


	if cmd == "area" then
		if str == "" then
			self:command(client, "areas",str,args)
			return true
		end

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
		dialogue=tostring(room.name),
		name=">",
		side=client.side or SIDE_WIT,

		pair = "Phoenix",
		pair_hscroll = 100,
		pair_emote = "-",
		pair_flip = 0,
		hscroll = 100,
	})
end

function rooms:arealist(client)
	if config.listareas then
		self:command(client,"areas")
	end
end

return rooms
