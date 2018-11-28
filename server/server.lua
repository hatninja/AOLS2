--[[Here's an overview of how this software is structured.
Server - Handles server socket and client communication.
Protocol - Translates client messages into process-readable objects and vice-versa.
Process - Handles all the basic behaviour of an AO server. Characters, Messages, Music, etc.
Modules - Extends process via callbacks and can add any functionality.
]]
--Server: Handles all communciation, delegates to process and protocols (via client objects).

local RECEIVEMAX = 2048
local SENDMAX = 2048

local server = {
	software = "AOLS2",
	version = "alpha",
}

function server:start()
	self:listen()
	self:reload()
end

function server:listen()
	self.socket = socket.tcp()
	self.socket:setoption("reuseaddr",true)
	self.socket:setoption("keepalive",false) --Prevent random disconnects, hopefully.
	self.socket:settimeout(0)

	assert(self.socket:bind(config.ip,config.port))
	local ip,port = self.socket:getsockname()
	verbosewrite("Bound to "..ip..":"..port..".\n")

	assert(self.socket:listen(config.maxplayers))
	print("Server is now listening for up to "..config.maxplayers.." players.")
end

function server:reload()
	if self.clients then
		for k,client in pairs(self.clients) do
			--TODO: Change to client:close()
			client.socket:close()
		end
	end
	self.clients = {}

	self.protocols = {
		dofile(path.."server/protocols/ao2.lua"),
		dofile(path.."server/protocols/websocket.lua")
	}

	self.process = dofile(path.."server/process.lua")
	self.process:start(self)
	verbosewrite("Server loaded and running!\n")
end

function server:update()
	repeat
		local client = self.socket:accept()
		if client then
			client:settimeout(0)
			--TODO: Implement client:close, good shorthand and allows protocols to do it properly.
			self.clients[client] = {
				socket=client,
				buffer="",
				received="",

				server=self,
				process=self.process,
				sendraw = function(cli,msg) cli.buffer = cli.buffer .. msg end,
				send = function(cli,...) cli.protocol:send(cli,self.process,...) end,
			}
		end
	until not client

	for k,client in pairs(self.clients) do
		--Receive data
		local data = ""
		repeat
			local char,err = client.socket:receive(1)
			if char then
				data = data .. char

				if #data > RECEIVEMAX then --A failsafe against impossibly large messages.
					print("A client is sending too much data!")
					break
				end
			else
				if err == "closed" then
					self.process:disconnect(client)
					self.clients[k] = nil
					break
				end
			end
		until not char
		client.received = client.received .. data

		if not client.protocol then
			for i,protocol in ipairs(server.protocols) do
				if protocol:detect(client,self.process) then
					self.process:accept(client)
				end
			end
		end
		if client.protocol then
			client.protocol:update(client,self.process)
			self.process:updateClient(client)
		end

		--Send data
		if self.clients[k] then
			local data = client.buffer:sub(1,SENDMAX)
			if #data > 0 then
				print("SERVERRAW",data)
				client.socket:send(data)
			end
			client.buffer = client.buffer:sub(SENDMAX+1,-1)
		end
	end

	self.process:update()
end

function server:close()
	self.socket:close()
	self.kill = true
end

return server
