--Process: Handles basic server behaviour, provides the modules functionality.
--[[
	Implemented events:
	"client_join"
	"player_join"
	"player_done"
	"player_leave"
	"character_pick"
	"ooc"
	"ooc_received"
	"emote"
	"emote_received"
	"music_play"
	"music_received"
	"event_play"
	"event_received"
	"bg_received"
	"call_mod"
	"update"
	"player_update"
]]
local process = {
	name = "Server",
	id = -1
}

local Music = dofile(path.."server/classes/music.lua")
local Character = dofile(path.."server/classes/character.lua")

function process:start(server)
	math.randomseed(os.time())
	math.random()math.random()

	self.server = server

	self.viewers = {}
	self.viewercount = 0

	self.players = {}
	self.firstempty = 1
	self.playercount = 0

	self.rooms = {}

	self.callbacks = {}
	self.modules = {}

	self.characters = {}
	self.music = {}
	self.backgrounds = {}

	self.time = 0

	verbosewrite("--Reading Assets--\n")

	local characters = self:loadList(path.."config/characters.txt")
	for i,char in ipairs(characters) do
		local s, e = char:find(": ")
		self.characters[i] = Character:new(
			s and char:sub(1,s-1) or char,
			e and track:sub(e+1,-1) or "wit"
		)
	end
	verbosewrite(#self.characters.." characters loaded!\n")

	self.music = {}
	local music = self:loadList(path.."config/music.txt")
	for i,track in ipairs(music) do
		local s, e = track:find(": ")
		self.music[i] = Music:new(
			s and track:sub(1,s-1) or track,
			e and tonumber(track:sub(e+1,-1)) or 0
		)
	end
	verbosewrite(#self.music.." music tracks loaded!\n")

	self.backgrounds = self:loadList(path.."config/backgrounds.txt")
	verbosewrite(#self.backgrounds.." backgrounds loaded!\n")


	
	verbosewrite("--Loading Modules--\n")
	local modules = self:loadList(path.."config/modules.txt")
	for i,name in ipairs(modules) do
		local chunk,err = loadfile(path.."server/modules/"..name..".lua")
		if chunk then
			local suc, module = pcall(chunk, self)
			if suc then
				if type(module) == "table" then
					if not module.name then module.name = name end
					module.print = self.print
					self.modules[name] = module
				else
					verbosewrite("👎 Warning: No module object in '"..name.."'\n")
				end
			else
				print("👎 Error with "..name..": "..module)
			end
		else
			print("👎 Error with "..name..": "..err)
		end
	end
	for i,name in ipairs(modules) do
		local module = self.modules[name]
		if module then
			if type(module.init) == "function" then
				module:init(self)
				verbosewrite("👍 '"..name.."' loaded!\n")
			end
		end
	end
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
		})
	end
	if call == "JOIN_REQ" then
		if client.id then return end --No duplicates!
		if self:event("client_join",client) then
			client:send("JOIN_ALLOW")
			self:join(client)
		end
	end

	--Ignore any other messages if client has not joined yet.
	if not client.id then return end

	if call == "LOAD_CHARS" then
		client:send("SEND_CHARS",self:getCharacters())
	end
	if call == "LOAD_MUSIC" then
		client:send("SEND_MUSIC",self:getMusic())
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
					self:sendEmote(client,ic_received)
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
					self:sendMusic(client,mp_received.track,mp_received.character,mp_received.name)
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
					receiver:send("EVENT", event_received)
				end
			end
		end
	end

	if call == "MOD_CALL" then
		self:event("call_mod", client, data)
	end
end

function process:accept(client)
	self.viewers[client] = client
	self.viewercount = self.viewercount + 1

	client.jointime = self.time
end

function process:join(client)
	self.players[self.firstempty] = client
	client.id = self.firstempty
	self.playercount = self.playercount + 1

	repeat
		self.firstempty = self.firstempty+1
	until not self.players[self.firstempty]

	self.viewers[client] = nil
	self.viewercount = self.viewercount - 1

	self:event("player_join",client)
	self:print("Player "..client.ip ..":".. client.port .." joined with ID: ".. client.id)
end

function process:disconnect(client)
	if client.id then
		if self:event("player_leave",client) then
			self.players[client.id] = nil
			self.playercount = self.playercount - 1
			self.firstempty = math.min(client.id,self.firstempty)
			
			self:print("Player with ID "..client.id.." disconnected.")
		end
	else
		self.viewers[client] = nil
		self.viewercount = self.viewercount - 1
	end
end

function process:update()
	self:event("update",client)
	
	self.time = self.time + config.rate
end

function process:updateClient(client)
	if client.id then
		self:event("player_update",client)

		if client.loopat and process.time > client.loopat then
			self:sendMusic(client,client.music,-1)
		end
	end
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

--API helpers
function process:assertValue(value,kind,argi)
	if type(value) ~= kind then error("Error: Expected "..kind.." value at argument #"..argi.."! Got "..type(value).." instead.",3) end
end


-----------------------
--General API functions
-----------------------
function process:print(text)
	print(os.date("%x %H:%M",os.time()).." ["..(self.name or "N/A").."] "..text)
end
function process:event(name,...)
	if self.callbacks[name] then
		for i,callback in ipairs(self.callbacks[name]) do
			if callback[1](callback[3],...) then return false end
		end
	end
	return true
end
function process:registerCallback(module,name,priority,func)
	if type(module) ~= "table" then error("Expected module object at arg #1!",2) end
	if not name then error("Expected event name at arg #2!",2) end
	if not tonumber(priority) then error("Expected priority number at arg #3!",2) end
	if type(func) ~= "function" then error("Expected function at arg #4!",2) end

	if not self.callbacks[name] then self.callbacks[name] = {} end
	table.insert(self.callbacks[name],{func,priority,module})
	table.sort(self.callbacks[name],function(a,b) return a[2] > b[2] end)
end
function process:loadList(dir)
	local t = {}
	local file = io.open(dir)
	if file then
		for line in file:lines() do
			if line:sub(1,1) ~= "#" and line:find("%S") then
				table.insert(t,line)
			end
		end
	end
	return t
end
function process:saveList(list,dir)
	local file = io.open(dir,"w")
	for i=1,#list do local v = list[i]
		if v then
			file:write(v.."\n")
		end
	end
	file:close()
end

function process:getCharacters(client)
	local characters = self:clone(self.characters)
	if self:event("list_characters",characters) then
		if config.shuffle then
			local list = {}
			for i,v in ipairs(characters) do table.insert(list,v) end
			local count = #list
			while count > 1 do
				local rand = math.random(1,count)
				list[rand], list[count] = list[count], list[rand]
				count=count-1
			end
		end
		return list or self.characters
	end

end
function process:getMusic(client)
	local music = self:clone(self.music)
	if self:event("list_music", music) then
		if config.shuffle then
			local list = {}
			for i,v in ipairs(music) do table.insert(list,v) end
			local count = #list
			while count > 1 do
				local rand = math.random(1,count)
				list[rand], list[count] = list[count], list[rand]
				count=count-1
			end
			table.insert(list,1,Music:new("-"))
			table.insert(list,2,Music:new("-.mp3"))
		end
		return list or self.music
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
		until self.players[id] or id > #self.players

		return self.players[id]
	end
end

function process:sendMessage(receiver,message,ooc_name)
	local ooc = {
		name=ooc_name or config.serverooc,
		message=message
	}
	
	if type(receiver) ~= "table" then error("A receiving object is required for arg #1!",2) end

	--Seamless message
	local ls,le = message:find("|: ")
	if ls then
		ooc.name = ooc.name .. message:sub(1,ls-1)
		ooc.message = message:sub(le+1,-1)
	end
	
	if receiver.players then
		for k,player in pairs(receiver.players) do
			player:send("OOC", ooc)
		end
	else
		receiver:send("OOC", ooc)
	end
end
function process:sendEmote(client,emote)
	local ic = {}
	for k,v in pairs(emote) do
		ic[k] = v
	end

	client:send("IC", ic)
end
function process:sendMusic(client,music,character,name)
	local track = type(music) == "table" and music:getName() or tostring(music)
	client.music = track

	client.loopat = nil
	for i,music in ipairs(self:getMusic()) do
		if music.name == track then
			if music.length ~= 0 then
				client.loopat = self.time + music.length
			end
			break
		end
	end

	client:send("MUSIC", {track=track, character=character, name=name})
end
function process:sendEvent(client,event,t)
	t.event = event
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

function process:getSideName(side)
	if side == SIDE_WIT then return "Witness"
	elseif side == SIDE_DEF then return "Defense"
	elseif side == SIDE_PRO then return "Prosecution"
	elseif side == SIDE_JUD then return "Judge"
	elseif side == SIDE_HLD then return "Co-Defense"
	elseif side == SIDE_HLP then return "Co-Prosecution"
	elseif side == SIDE_JUR then return "Juror"
	else return "N/A"
	end
end

return process
