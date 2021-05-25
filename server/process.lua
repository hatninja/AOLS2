--Process: Handles basic server behaviour, provides the modules functionality.

local process = {
	name = "Server",
	id = -1
}

local Player = require("classes/player")
local Music = require("classes/music")
local Character = require("classes/character")

function process:start(server)
	self.server = server

	self.name = "Process"
	self.time = 0


	--Viewers are clients observing the server's status.
	self.viewers = {}
	self.viewercount = 0

	--Players are clients that explicitly join the server.
	self.players = {}
	self.firstempty = 1
	self.playercount = 0


	--Built-in Functionality.
	self.characters = {}
	self.music = {}

	verbose("-Assets-\n")

	verbose("Reading from config/characters.txt\n")
	local characters = self:loadList(path.."config/characters.txt")
	for i,char in ipairs(characters) do
		local s, e = char:find(": ")
		self.characters[i] = Character:new(
			s and char:sub(1,s-1) or char,
			e and track:sub(e+1,-1) or "wit"
		)
	end
	verbose(#self.characters.." characters loaded!\n")

	verbose("Reading from config/music.txt\n")
	self.music = {}
	local music = self:loadList(path.."config/music.txt")
	for i,track in ipairs(music) do
		local s, e = track:find(": ")
		self.music[i] = Music:new(
			s and track:sub(1,s-1) or track,
			e and tonumber(track:sub(e+1,-1)) or 0
		)
	end
	verbose(#self.music.." music tracks loaded!\n")

	verbose("-Events-\n")
	--Module functionality.
	self.modules = {}
	self.events = {}
	self.callbacks = {}

	self:registerEvents(
		"client_join",
		"player_join",
		"player_done",
		"player_leave",
		"player_update"
	)
	self:registerEvents(
		"done",
		"update",
		"close",
		"remove_module"
	)
	self:registerEvents(
		"ooc",
		"ooc_received",
		"emote",
		"emote_received",
		"music_play",
		"music_received",
		"event_play",
		"event_received",
		"bg_received",
		"call_mod",
		"character_pick"
	)
	self:registerEvents(
		"list_characters",
		"list_music"
	)
	self:registerEvents(
		"item_add",
		"item_remove",
		"item_edit",
		"item_list"
	)

	verbose("-Modules-\n")

	verbose("Reading from config/modules.txt\n")
	local modules = self:loadList(path.."config/modules.txt")
	for i,name in ipairs(modules) do
		local suc, err = self:loadModule(name)
		if not suc then
			print(f("👎 Error with ${1}: ${2}",name,err))
		end
	end
	for i,name in ipairs(modules) do
		local module = self.modules[name]
		if module then
			if type(module.init) == "function" then
				module:init(self)
				verbose(f("👍 '${1}' loaded!\n",name))
			end
		end
	end

	self:event("done",process)
end

--Message sent from client to process via protocol
function process:send(client, call, data)
	if call == "INFO_REQ" then
		client:send("INFO_SEND",{
			software = self.server.software,
			version = self.server.version,

			name = config.name,
			description = config.desc,

			maxplayers = config.maxplayers,
			players = self.playercount,

			uptime = self.time,
		})
	end
	if call == "JOIN_REQ" then
		if client.id then return end
		if self:event("client_join",client) then
			client:send("JOIN_ALLOW")
			self:join(client)
		end
	end

	--Ignore any other messages if client has not joined yet.
	if not client.id then return end

	if call == "LOAD_CHARS" then
		client:send("SEND_CHARS",data and self:clone(data) or self:getCharacters(client))
	end
	if call == "LOAD_MUSIC" then
		client:send("SEND_MUSIC",data and self:clone(data) or self:getMusic(client))
	end

	if call == "DONE" then
		self:event("player_done",client)
	end

	if call == "CHAR_REQ" then
		self:protocolStringAssert(call,data, "character")

		if self:event("character_pick", client, data.character) then
			client:send("CHAR_PICK",data)
			client.character = data.character
		else
			data.reason = "Invalid character!"
			data.code = 0
			client:send("CHAR_DENY",data)
		end
	end
	if call == "OOC" then
		self:protocolStringAssert(call,data, "name","message")

		if self:event("ooc", client, data) then
			for receiver in self:eachPlayer() do
				local ooc_received = self:clone(data)

				if self:event("ooc_received", client, receiver, ooc_received) then
					self:sendMessage(receiver,ooc_received.message,ooc_received.name)
				end
			end
		end
	end
	if call == "IC" then
		self:protocolStringAssert(call,data, "dialogue","character","emote")

		if self:event("emote", client, data) then
			for receiver in self:eachPlayer() do
				local ic_received = self:clone(data)

				if self:event("emote_received", client, receiver, ic_received) then
					self:sendEmote(receiver,ic_received)
				end
			end
		end
	end
	if call == "MUSIC" then
		self:protocolStringAssert(call,data, "track")

		if self:event("music_play", client, data) then
			for receiver in self:eachPlayer() do
				local mp_received = self:clone(data)

				if self:event("music_received", client, receiver, mp_received) then
					self:sendMusic(receiver,
					mp_received.track,
					mp_received.character,
					mp_received.name,
					mp_received.looping,
					mp_received.channel,
					mp_received.effects)
				end
			end
		end
	end

	if call == "EVENT" then
		self:protocolStringAssert(call,data, "event")

		if self:event("event_play", client, data) then
			--Not sure if events should be fully passthrough like the others.
			for receiver in self:eachPlayer() do
				local event_received = self:clone(data)

				if self:event("event_received", client, receiver, event_received) then
					self:sendEvent(receiver, event_received)
				end
			end
		end
	end

	if call == "ITEM_ADD" then
		self:protocolStringAssert(call,data, "name","description","image")
		if self:event("item_add",client,data) then
			self:sendItems(client,{})
		end
	end

	if call == "ITEM_REMOVE" then
		if self:event("item_remove",client,data.id) then
			self:sendItems(client,{})
		end
	end

	if call == "ITEM_EDIT" then
		self:protocolStringAssert(call,data, "name","description","image")
		if self:event("item_edit",client,data.id,data) then
			self:sendItems(client,{})
		end
	end

	if call == "MOD_CALL" then
		self:event("call_mod", client, data)
	end

	if call == "CLOSE" then
		client:close()
	end
end

function process:accept(client)
	self.viewers[client] = client
	self.viewercount = self.viewercount + 1

	client.jointime = self.time
end

function process:join(client)
	if not self.viewers[client] then return end --If so, this is a repeat.

	self.viewers[client] = nil
	self.viewercount = math.max(self.viewercount - 1, 0)

	self.players[self.firstempty] = client
	client.id = self.firstempty

	repeat
		self.firstempty = self.firstempty+1
	until not self.players[self.firstempty]

	self.playercount = self.playercount + 1

	Player.init(client)

	self:event("player_join",client)
	self:print(f("Player ${ip}:${port} joined with ID: ${id}",client))
end

function process:disconnect(client)
	if client.id then
		if self:event("player_leave",client) then
			self.players[client.id] = nil
			self.playercount =  math.max(self.playercount - 1, 0)
			self.firstempty = math.min(client.id,self.firstempty)

			self:print("Player with ID "..client.id.." disconnected.")
		end
	else
		self.viewers[client] = nil
		self.viewercount =  math.max(self.viewercount - 1, 0)
	end
end

function process:update()
	self:event("update",process)

	self.time = self.time + config.rate
end

function process:updateClient(client)
	if client.id then
		self:event("player_update",client)

		if client.loopat and self.time > client.loopat then
			self:sendMusic(client,client.music,-1)
		end
	else
		if self.time > client.jointime+(config.viewertime or 120) then
			client:close()
		end
	end
end

function process:close()
	self:event("close")
end

--Protocol handling functions
function process:protocolStringAssert(call,data,...)
	local list = {...}
	for i,key in ipairs(list) do
		if type(data[key]) ~= "string" then
			error("Protocol Error: "..call.."."..key.." is not a string!",3)
		end
	end
end
function process:protocolNumberAssert(call,data,...)
	local list = {...}
	for i,key in ipairs(list) do
		if type(data[key]) ~= "number" then
			error("Protocol Error: "..call.."."..key.." is not a number!",3)
		end
	end
end

function process:clone(tc)
	local clone = {}
	for k,v in pairs(tc) do
		clone[k] = v
	end
	return clone
end

function process:loadModule(name)
	local chunk,err = loadfile(path.."server/modules/"..name..".lua")
	if not chunk then return nil,err end

	local suc, module = pcall(chunk, self)
	if not suc then return nil,module end

	if type(module) == "table" then
		if not module.name then module.name = name end
		module.print = self.print
		self.modules[name] = module
	else
		verbose("👎 Warning: No module object in '"..name.."'\n")
	end
	return module
end

function process:removeModule(name)
	local module = self.modules[name]
	if not module then
		verbose("👎 Warning: Module '"..name.."' already removed!\n")
		return
	end

	self:event("close_module",name)

	self.modules[name] = nil
	for event,callbacks in pairs(self.callbacks) do
		for i=#callbacks,1,-1 do
			if callbacks[i][3] == module then
				table.remove(callbacks,i)
			end
		end
	end
	return true
end

--API helpers
function process:assertValue(value,kind,argi)
	if type(value) ~= kind then error("Error: Expected "..kind.." value at argument #"..argi.."! Got "..type(value).." instead.",3) end
end
-------------------------
--General API functions--
-------------------------
--Modules
function process:print(text,...)
	local formatted = f(text,...)
	print(f("${1} [${2}] ${3}",os.date("%x %H:%M",os.time()),self.name,formatted))
end
function process:getModule(name)
	return name and self.modules[name]
end
--Events & Callbacks
function process:event(name,...)
	if not self.events[name] then
		print("Warning: Sent unregistered event: '"..name.."'")
	end
	if self.callbacks[name] then
		for i,callback in ipairs(self.callbacks[name]) do
			if callback[1](callback[3],...) then return false end
		end
	end
	return true
end
function process:registerEvents(...)
	local newEvents = {...}
	verbose("Registered event: ")
	for i=1,#newEvents do
		local name = tostring(newEvents[i])
		if self.callbacks[name] then
			print("Warning: Tried to register '"..name.."' twice!")
			return
		end

		verbose((i==1 and "" or ", ")..name)
		self.events[name] = true
		self.callbacks[name] = {}
	end
	verbose("\n")
end
function process:registerCallback(module,name,priority,func)
	if type(module) ~= "table" then error("Expected module object at arg #1!",2) end
	if not name then error("Expected event name at arg #2!",2) end
	if not tonumber(priority) then error("Expected priority number at arg #3!",2) end
	if type(func) ~= "function" then error("Expected function at arg #4!",2) end

	if not self.callbacks[name] then
		print("Warning: Registered callback to unregistered event: '"..name.."'")
		self.callbacks[name] = {}
	end
	table.insert(self.callbacks[name],{func,priority,module})
	table.sort(self.callbacks[name],function(a,b) return a[2] > b[2] end)
end
--General Utility
function process:loadList(dir)
	local t = {}
	local file = io.open(dir)
	if file then
		for line in file:lines() do
			if line:sub(1,1) ~= "#" and line:find("%S") then
				table.insert(t,line)
			end
		end
		file:close()
	end
	return t
end
function process:saveList(list,dir)
	local file = io.open(dir,"w")
	if file then
		for i=1,#list do local v = list[i]
			if v then
				file:write(v.."\n")
			end
		end
		file:close()
	end
end
--Process Utility
function process:getCharacters(client)
	local characters = self:clone(self.characters)
	if self:event("list_characters", client, characters) then
		return characters
	end

end
function process:getMusic(client)
	local music = self:clone(self.music)
	if self:event("list_music", client, music) then
		return music
	end
end
function process:getBackgrounds(client)
	return backgrounds
end

function process:getPlayer(id)
	if tonumber(id) and self.players[id] then
		return self.players[id]
	end
end
function process:eachPlayer()
	local id = 0
	return function()
		repeat id = id+1
		until self.players[id] or id > 255

		return self.players[id]
	end
end
--Specialized Senders
function process:sendMessage(receiver,message,ooc_name)
	local ooc = {
		name=ooc_name,
		message=message
	}

	if not ooc_name then
		ooc.name = config.serverooc
		ooc.server = true
	end

	if type(receiver) ~= "table" then error("A receiving object is required for arg #1!",2) end

	if receiver.players then
		for k,player in pairs(receiver.players) do
			player:send("OOC", ooc)
		end
	else
		receiver:send("OOC", ooc)
	end
end
function process:sendEmote(client,emote)
	local ic = self:clone(emote)
	client:send("IC", ic)
end
function process:sendMusic(client,music,character,name,looping,channel,effects)
	local track = type(music) == "table" and music:getName() or tostring(music)
	client.music = track

	client.loopat = nil
	for i,music in ipairs(self:getMusic()) do
		if music.name == track then
			if music.length and music.length ~= 0 then
				client.loopat = self.time + music.length
			end
			break
		end
	end

	client:send("MUSIC", {
		track=track,
		character=character,
		name=name,
		looping=type(music) == "table" and music.looping or looping,
		channel=type(music) == "table" and music.channel or channel,
		effects=type(music) == "table" and music.effects or effects,
	})
end
function process:sendEvent(client,t)
	client:send("EVENT", t)
end
function process:sendBG(client,bg)
	if bg ~= client.bg then
		local t = {bg=bg}
		if self:event("bg_received",client,t) then
			client.bg = t.bg
			client:send("BG", t)
		end
	end
end
function process:sendItems(client,list)
	if self:event("item_list",client,list) then
		client:send("ITEM_LIST", list)
	end
end
function process:sendNotice(client,msg)
	client:send("NOTICE", {message = msg})
end
function process:sendKick(client,msg)
	client:send("KICK", {reason = msg})
end
function process:sendBan(client,msg)
	client:send("BAN", {reason = msg})
end
--Process Behaviour
function process:getSideName(side)
	if side == SIDE_WIT then return "Witness"
	elseif side == SIDE_DEF then return "Defense"
	elseif side == SIDE_PRO then return "Prosecution"
	elseif side == SIDE_JUD then return "Judge"
	elseif side == SIDE_HLD then return "Co-Defense"
	elseif side == SIDE_HLP then return "Co-Prosecution"
	elseif side == SIDE_JUR then return "Juror"
	elseif side == SIDE_SEA then return "Seance"
	else return "N/A"
	end
end

--DEPRECATED
function process:registerEvent(name)
	trace(2) warn "registerEvent is deprecated!"
	self:registerEvents(name)
end

return process
