--[[Here's an overview of how this software is structured.
Server - Handles server socket and client communication.
Protocol - Translates client messages into process-readable objects and vice-versa.
Process - Handles all the basic behaviour of an AO server. Characters, Messages, Music, etc.
Modules - Extends process via callbacks and can add any functionality.
]]
--Server: Handles all communciation, delegates to process and protocols (via client objects).

local RECEIVEMAX = 2048
local SENDMAX = 4096

local server = {
	software = "AOLS2",
	version = "2.0",
}

local Client = require("classes/client")

function server:start()
	self:listen()
	self:reload()
end

function server:listen()
	self.socket = socket.tcp()
	self.socket:setoption("reuseaddr",true)
	self.socket:setoption("keepalive",true)
	self.socket:settimeout(0)

	assert(self.socket:bind(config.ip,config.port))
	local ip,port = self.socket:getsockname()
	verbosewrite("Bound to "..ip..":"..port..".\n")

	assert(self.socket:listen(config.maxplayers))
	print("Server is now listening for up to "..config.maxplayers.." players.")
end

function server:reload()
	config = {}
	dofile(path.."config/config.lua")(config)

	if self.clients then
		for k,client in pairs(self.clients) do
			client:close()
		end
	end
	self.clients = {}

	self.protocols = {
		dofile(path.."server/protocols/ao2.lua"),
		dofile(path.."server/protocols/websocket.lua"),
	}

	self.process = dofile(path.."server/process.lua")
	self.process:start(self)
	print("--Finished, now running--")
end

function server:update()
	local self = server

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
		local data = ""
		repeat
			local char,err = client:receive(1)
			if char then
				data = data .. char
				if #data > RECEIVEMAX then --Failsafe against impossibly large messages.
					print("Receiving excessive data!",client:getAddress())
					client:close()
					data=""
					break
				end
			end
		until not char
		client.received = client.received .. data

		--Determine protocol
		if not client.protocol then
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
			client.protocol:update(client,self.process)
		end

		--Send data
		local data = client.buffer:sub(1,SENDMAX)
		if #data < #client.buffer then
			print("Sending excessive data!",client:getAddress())
		end
		if #client.buffer > 0 then
			client:sendraw(data)
		end
		client.buffer = client.buffer:sub(SENDMAX+1,-1)


		--Remove closed clients.
		if not client.socket then
			self.clients[k] = nil
		end
	end

	self.process:update()
end

function server:close()
	self.socket:close()
	self.kill = true
end

return server
