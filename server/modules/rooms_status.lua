--Handles the room status display. Room status, name, and doc commands are also handled.
local process = ...

local DISPLAY_RATE = 3

local rooms = {
	name = "Rooms",

	help = {
		{"doc","(link)","Shows the document for the room.","Add a link to change the room's doc.\n'clear' can be used to remove the doc.",},
		{"status","(status)","Change the status of the room."},
		{"rename","(name)","Changes the name of your room."},
	}
}

function rooms:init()
	self.parent = process.modules["rooms"]

	process:registerEvent("room_doc")
	process:registerEvent("room_status")

	process:registerCallback(self,"command", 3,self.command)
	process:registerCallback(self,"update", 3,self.update)

	process:registerCallback(self,"player_done", 0,self.join)
	process:registerCallback(self,"player_move", 0,self.count_update)
	process:registerCallback(self,"player_leave", 0,self.count_update)

	process:registerCallback(self,"room_lock", 0,self.lock_update)
	process:registerCallback(self,"room_status", 0,self.status_update)
	process:registerCallback(self,"room_cm", 0,self.cm_update)


	--Must match the area list in the area selector
	self.roomlist = {}
	for k,room in pairs(self.parent.rooms) do
		if not room.hidden then
			table.insert(self.roomlist, room)
		end
	end

	self.updatetimer = DISPLAY_RATE
	self.countchange = false
	self.statuschange = false
	self.cmchange = false
	self.lockchange = false
end

function rooms:update()
	self.updatetimer = self.updatetimer - config.rate
	if self.updatetimer < 0 then
		self.updatetimer = self.updatetimer + DISPLAY_RATE
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
			v.doc = nil
			if v.basename then
				v.name = v.basename
			end
		end
	end
end


function rooms:displaycount(client)
	local counts = {}
	for i,v in pairs(self.roomlist) do
		table.insert(counts,v.count)
	end
	counts.event = "arup_count"
	if client then
		process:sendEvent(client,counts)
	else
		for player in process:eachPlayer() do
			process:sendEvent(player,counts)
		end
	end
end
function rooms:displaystatus(client)
	local statuses = {}
	for i,v in pairs(self.roomlist) do
		table.insert(statuses,v.status or "")
	end
	statuses.event = "arup_status"
	if client then
		process:sendEvent(client,statuses)
	else
		for player in process:eachPlayer() do
			process:sendEvent(player,statuses)
		end
	end
end
function rooms:displaycm(client)
	local cms = {}
	for i,v in pairs(self.roomlist) do
		local cm = "None"
		if v.cm then
			cm = "["..tostring(v.cm).."]"
		end
		table.insert(cms, cm)
	end
	cms.event = "arup_cm"
	if client then
		process:sendEvent(client,cms)
	else
		for player in process:eachPlayer() do
			process:sendEvent(player,cms)
		end
	end
end

function rooms:displaylock(client)
	local locks = {}
	for i,v in pairs(self.roomlist) do
		local lock = "OPEN"
		if v.lock then
			lock = "LOCKED"
		end
		if v.whitelist then
			lock = "SPECTATE"
		end
		if v.modlock then
			lock = "MODS-ONLY"
		end

		table.insert(locks,lock)
	end
	locks.event = "arup_lock"
	if client then
		process:sendEvent(client,locks)
	else
		for player in process:eachPlayer() do
			process:sendEvent(player,locks)
		end
	end
end

function rooms:command(client, cmd,str,args)
	if cmd == "doc" then
		local room = client.room
		if room then
			if args[1] then
				if process:event("room_doc",client,room,args[1]) then
					if args[1] == "clear" then
						room.doc = nil
						process:sendMessage(room,client:getIdent().." cleared the doc.")
					else
						room.doc = args[1]
						process:sendMessage(room,client:getIdent().." changed the room's doc!")
					end
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
				local status = string.upper(args[1])
				if process:event("room_status",room,status) then
					if #args[1] <= #("LOOKING-FOR-PLAYERS") then
						room.status = status
						process:sendMessage(room,client:getIdent().." changed the room's status to '"..room.status.."'")
					else
						process:sendMessage(client,"Your staus name is too long!")
					end
				end
			else
				room.status = nil
				process:sendMessage(room,client:getIdent().." removed the room's status.")
			end

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
				if #str <= config.maxrename then
					room.name = str
					process:sendMessage(room,client:getIdent().." renamed the room to '"..room.name.."'")
				else
					process:sendMessage(client,"Your room name is too long!")
				end
			else
				room.name = room.basename
				process:sendMessage(room,client:getIdent().." unnamed the room!")
			end
			return true
		end
	end
end

function rooms:join(client)
	self:displaystatus(client)
	self:displaycm(client)
	self:displaylock(client)
	self.countchange = true
end

function rooms:count_update()
	self.countchange = true
end
function rooms:cm_update()
	self.cmchange = true
end
function rooms:lock_update()
	self.lockchange = true
end
function rooms:status_update()
	self.statuschange = true
end

return rooms
