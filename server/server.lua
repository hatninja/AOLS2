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
	version = "1.0",
}

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
		dofile(path.."server/protocols/websocket.lua")
	}

	self.process = dofile(path.."server/process.lua")
	self.process:start(self)
	print("--Finished, now running--")
end

function server:update()
	local self = server
	repeat
		local client = self.socket:accept()
		if client then
			client:settimeout(0)
			local cip, cport = client:getpeername()
			verbosewrite("Accepted connection from "..cip..":"..cport.."\n")
			self.clients[client] = {
				socket=client,
				buffer="",
				received="",

				ip=cip,
				port=cport,

				server=self,
				process=self.process,
				sendraw = function(cli,msg) cli.buffer = cli.buffer .. msg end,
				send = function(cli,...) cli.protocol:send(cli,self.process,...) end,
				close = function(cli,...)
					if client.protocol then
						client.protocol:close(client)
					end
					cli.socket:close()
				end,
			}
		end
	until not client

	for k,client in pairs(self.clients) do
		if client.socket then
			--Receive data
			local data = ""
			repeat
				local char,err = client.socket:receive(1)
				if char then
					data = data .. char

					if #data > RECEIVEMAX then --Failsafe against impossibly large messages.
						print("Receiving excessive data!",client.ip,client.port)
						client:close()
						data=""
						break
					end
				else
					if err == "closed" then
						self.process:disconnect(client)
						self.clients[k] = nil
						client.socket = nil
						break
					end
				end
			until not char
			client.received = client.received .. data

			if self.clients[k] then
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
				if #data < #client.buffer then print("Sending excessive data!",client.ip,client.port) end
				if #data > 0  then
					client.socket:send(data)
				end
				client.buffer = client.buffer:sub(SENDMAX+1,-1)
			end
		end
	end

	self.process:update()
end

function server:close()
	self.socket:close()
	self.kill = true
end

return server
