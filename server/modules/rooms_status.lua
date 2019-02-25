--Handles room management and ARUP.
local process = ...

local Music = dofile(path.."server/classes/music.lua")

local rooms = {
	name = "Rooms",

	help = {
		{"doc","(link)","Shows the document for the room.","Add a link to change the room's doc."},
		{"status","(status)","Change the status of the room."},
		{"rename","(name)","Changes the name of your area."},
		{"lock","(pass)","Locks a room with a passcode."},
		{"key","(pass)","Sets your key. Allows you to enter rooms with the same passcode."},
	}
}

function rooms:init()
	self.parent = process.modules["rooms"]

	process:registerCallback(self,"command", 3,self.command)
	process:registerCallback(self,"update", 3,self.update)

	process:registerCallback(self,"player_done", 3,self.join)
	process:registerCallback(self,"player_move", 4,self.move)

	--Must match the area list in the area selector
	self.roomlist = {}
	for k,room in pairs(self.parent.rooms) do
		if not room.hidden then
			table.insert(self.roomlist, room)
		end
	end

	self.updatetimer = 1
	self.countchange = false
	self.statuschange = false
	self.cmchange = false
	self.lockchange = false
end

function rooms:update()
	self.updatetimer = self.updatetimer - config.rate
	if self.updatetimer < 0 then
		self.updatetimer = self.updatetimer + 1
		if self.countchange then
			self.countchange = false
			self:displaycount()
		end
		if self.statuschange then
			self.statuschange = false
			self:displaystatus()
		end
		if self.cmchange then
			self.cmchange = false
			self:displaycm()
		end
		if self.lockchange then
			self.lockchange = false
			self:displaylock()
		end
	end
	
	local parent = process.modules["rooms"]
	for k,v in pairs(parent.rooms) do
		if v.count == 0 then
			if v.status then
				v.status = nil
				self.statuschange = true
			end
			if v.lock then
				v.lock = nil
				self.lockchange = true
			end
			v.doc = nil
			if v.basename then
				v.name = v.basename
			end
		end
	end
end
function rooms:displaycount()
	local counts = {}
	for i,v in pairs(self.roomlist) do
		table.insert(counts,v.count)
	end
	counts.event = "arup_count"
	for player in process:eachPlayer() do
		process:sendEvent(player,counts)
	end
end
function rooms:displaystatus()
	local statuses = {}
	for i,v in pairs(self.roomlist) do
		table.insert(statuses,v.status or "")
	end
	statuses.event = "arup_status"
	for player in process:eachPlayer() do
		process:sendEvent(player,statuses)
	end
end
function rooms:displaycm()
	local cms = {}
	for i,v in pairs(self.roomlist) do
		table.insert(cms,v.cm or "")
	end
	cms.event = "arup_cm"
	for player in process:eachPlayer() do
		process:sendEvent(player,cms)
	end
end
function rooms:displaylock()
	local locks = {}
	for i,v in pairs(self.roomlist) do
		local lock = "OPEN"
		if v.lock then
			lock = "LOCKED"
		end
		if v.spectate then
			lock = "SPECTATE-ONLY"
		end
		if v.modlock then
			lock = "MODS-ONLY"
		end
		table.insert(locks,lock)
	end
	locks.event = "arup_lock"
	for player in process:eachPlayer() do
		process:sendEvent(player,locks)
	end
end

function rooms:command(client, cmd,str,args)
	if cmd == "doc" then
		local room = client.room
		if room then
			if args[1] then
				if args[1] == "clear" then
					room.doc = nil
					process:sendMessage(room,"["..client.id.."] cleared the doc.")
				else
					room.doc = args[1]
					process:sendMessage(room,"["..client.id.."] changed the room's doc!")
				end
			else
				process:sendMessage(client,room.doc or "No doc set!")
			end
			return true
		end
	end
	if cmd == "status" then
		local room = client.room
		if room then
			if args[1] then
				if #args[1] <= #("LOOKING-FOR-PLAYERS") then
					room.status = string.upper(args[1])
					process:sendMessage(room,"["..client.id.."] changed the room's status to '"..room.status.."'")
				else
					process:sendMessage(client,"Your staus name is too long!")
				end
			else
				room.status = nil
				process:sendMessage(room,"["..client.id.."] removed the room's status.")
			end
			self.statuschange = true
			return true
		end
	end
	if cmd == "lock" then
		local room = client.room
		if room then
			if args[1] then
				room.lock = args[1]
				process:sendMessage(room,"["..client.id.."] locked the room with passcode '"..room.lock.."'")
			else
				room.lock = nil
				process:sendMessage(room,"["..client.id.."] removed the room's lock.")
			end
			self.lockchange = true
			return true
		end
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
			self.lockchange = true
			return true
		end
	end
	if cmd == "rename" then
		local room = client.room
		if room then
			if not room.renamable then
				process:sendMessage(client,"This room isn't renamable!")
				return true
			end
			if not room.basename then
				room.basename = room.name
			end

			if str ~= "" then
				if #str <= 20 then
					room.name = str
					process:sendMessage(room,"["..client.id.."] renamed the room to '"..room.name.."'")
				else
					process:sendMessage(client,"Your room name is too long!")
				end
			else
				room.name = room.basename
				process:sendMessage(room,"["..client.id.."] unnamed the room!")
			end
			self.statuschange = true
			return true
		end
	end
end

function rooms:join(client)
	self:displaycount()
	self:displaystatus()
	self:displaycm()
	self:displaylock()
end

function rooms:move(client, targetroom, sourceroom)
	if targetroom.lock and targetroom.lock ~= client.key then
		process:sendMessage(client,"Cannot enter! Please enter with the right passcode via /key")
		return true
	end
	if targetroom.modlock and not client.mod then
		process:sendMessage(client,"This room is moderator-only!")
		return true
	end

	self.countchange = true
end

return rooms