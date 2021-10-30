--[[Overview of the software structure:
Server
	Handles the server socket and and the low level of client connections.
Process
	Runs the basic behaviour of the server. Modules extend functionality.
Protocols
	Translates raw client messages into process-readable objects and vice-versa.
]]

local RECEIVEMAX = 4096
local SENDMAX = 4096

local server = {
	software = "AOLS2",
	version = "git",
}

local Client = require("classes/client")

function server:start()
	verbose(self.software.." ("..self.version..")\n")

	self:reload()
	self:listen()
end

function server:listen()
	verbose("-Socket-\n")
	self.socket = socket.tcp()
	self.socket:setoption("reuseaddr",true)
	self.socket:setoption("keepalive",true)
	self.socket:settimeout(0)

	assert(self.socket:bind(config.ip,config.port))

	self.ip,self.port = self.socket:getsockname()
	verbose(f("Bound to ${ip}:${port}\n",self))

	assert(self.socket:listen(config.maxplayers))
	print(f("Server is now listening for up to ${maxplayers} players.",config))
end

function server:reload()
	--reload() may be called more than once to update configuration.
	if self.process then
		self.process:close()
	end
	if self.clients then
		for k,client in pairs(self.clients) do
			client:close()
		end
	end

	config = {}
	dofile(path.."config/config.lua")(config)

	self.clients = {}

	self.protocols = {}
	local file = io.open(path.."config/protocols.txt")
	if file then
		for line in file:lines() do
			if line:sub(1,1) ~= "#" and line:find("%S") then
				local protocol = dofile(path.."server/protocols/"..line..".lua")
				table.insert(self.protocols,1,protocol)
			end
		end
		file:close()
	end

	self.process = dofile(path.."server/process.lua")
	self.process:start(self)
end

function server:close()
	self.process:close()

	self.socket:close()
	self.kill = true
end

local self = server --Lua 5.1 compatibility hack
function server.update()
	--Accept new connections
	repeat
		local connection,err = self.socket:accept()
		if connection then
			local client = Client:new(connection, self.process)
			self.clients[client] = client

			if config.monitor then
				print("Accepted connection from "..client:getAddress())
			end
		end
	until not connection

	for k,client in pairs(self.clients) do
		--Receive data
		local data,err = client:receive(RECEIVEMAX)
		if data then
			client.received = client.received .. data
			if #data == RECEIVEMAX then
				print("Receiving excessive data!",client:getAddress())
				client:close()
			end
		end

		--Detect and assign a client's protocol
		if not client.protocol and not client:isClosed() then
			for i,protocol in ipairs(self.protocols) do
				if protocol:detect(client,self.process) then
					self.process:accept(client)
					break
				end
			end
		end

		--Update client
		if client.protocol then
			self.process:updateClient(client)
			if client:isClosed() then
				self.process:disconnect(client)
			end
		end
		client:update()

		--Send data
		local data = client.buffer:sub(1,SENDMAX)
		if #data < #client.buffer then
			print("Sending excessive data!",client:getAddress())
		end
		if #client.buffer > 0 then
			client:sendraw(data)
		end
		client.buffer = client.buffer:sub(SENDMAX+1,-1)


		--Remove closed clients
		if not client.socket then
			self.clients[k] = nil
		end
	end

	self.process:update()
end

return server
