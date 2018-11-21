--Process handles all the base behaviours, further functionality is provided by letting modules extend via events.
local process = {}

--client:send is short for client.protocol:send(client,...)

--TODO: "Joined as client[1]""
--TODO: Auto present evidence
--TODO: Play sound effect if health changed.

--[[
process:start
Called when server is fully initialized.

process:send
Gets a message from a client in internal protocol.

process:accept
Called when a client connects to the server and the protocol has been chosen.

process:disconnect
Called when a client disconnects or is detected as closed.
]]

function process:start(server)
	math.randomseed(os.time())
	math.random()math.random()
	self.id = -1

	self.server = server

	self.viewers = {}
	self.viewercount = 0

	self.players = {}
	self.firstempty = 1
	self.playercount = 0

	self.callbacks = {}

	--Load from configuration
	self.characters = dofile(path.."config/characters.lua")

	dofile(path.."config/features.lua")


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
		if self:event("client_join",client) then
			client:send("JOIN_ALLOW")
			self:join(client)
		end
	end

	--Ignore any other messages if client has not joined yet.
	if not client.id then return end

	if call == "LIST_CHARS" then
	end
	if call == "LIST_MUSIC" then
	end

	if call == "CHAR_REQ" then
		self:protocolStringAssert(call,data, "character")

		if self:event("character_pick", client, data.character) then
			client:send("CHAR_PICK",data)
		else
			data.reason = "Invalid character!"
			data.code = 0
			client:send("CHAR_DENY",data)
		end
	end
	if call == "OOC" then
		self:protocolStringAssert(call,data, "name","message")

		if self:event("ooc", client, data) then
			for i,receiver in ipairs(self.players) do
				local ooc_received = {
					name=data.name,
					message=data.message
				}
				if self:event("ooc_received", client, receiver, ooc_received) then
					receiver:send("OOC", ooc_received)
				end
			end
		end
	end
	if n == "IC" then
		self:protocolStringAssert(call,data, "dialogue","character","name","emote","pre_emote")

		if self:event("emote", client, data) then
			for i,receiver in ipairs(self.players) do
				local ic_received = {}
				for k,v in pairs(data) do ic_received[k] = v end

				if self:event("emote_received", client, receiver, ic_received) then
					v:send("IC", ic_received)
				end
			end
		end
	end
end

function process:accept(client)
	self.viewers[client] = client
	self.viewercount = self.viewercount + 1

	client.jointime = os.time()
end

function process:join(client)
	self.players[self.firstempty] = client
	client.id = self.firstempty

	client.ip,client.port = client.socket:getpeername()
	repeat
		self.firstempty = self.firstempty+1
	until not self.players[self.firstempty]

	self.viewers[client] = nil
	self.viewercount = self.viewercount - 1

	self:print(client.ip ..":".. client.port .." is joining with ID: ".. client.id)
end

function process:disconnect(client)
	if client.id then
		self.players[client.id] = nil
		self.firstempty = math.min(client.id,self.firstempty)
	else
		self.viewers[client] = nil
		self.viewercount = self.viewercount - 1
	end
end

function process:update()
end

function process:updateClient(client)
end


--Events system:
function process:event(name,...)
	if self.callbacks[name] then
		for i,callback in ipairs(self.callbacks[name]) do
			if callback[1](...) then return false end
		end
	end
	return true
end
function process:registerCallback(name,priority,func)
	if not self.callbacks[name] then self.callbacks[name] = {} end
	table.insert(self.callbacks[name],{func,priority})
	table.sort(self.callbacks[name],function(a,b) return a[2] < b[2] end)
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

--API functions
function process:getCharacters(client)
	return self.characters
end

function process:print(text,caller)
	print(os.date("%x %H:%S").." ["..(caller or "Server").."]: "..text)
end


return process
