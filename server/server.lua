--[[Here's an overview of how this software is structured.

Accepting clients:

1. Client connects via TCP
2. All the protocol objects team up and try to learn the software/protocol that client is using.
2a. If a protocol recognizes the client, it is assigned to the client and handshakes can begin.
2b. If the client cannot be recognized, it is thrown out.

Updating clients:

1. Client sends message via TCP
2. The protocol translates the client's message and sends it over to processing.
3. Processing performs basic logic and sends special events to modules.
4. Modules receive those events and provide extra functionality.
5. Then protocol translates server calls into outgoing messages.
6. Finally, server message is sent via TCP.

server - Provides base functions for communicating with clients and updating the server state.
protocol - Communicates between internal protocol and the client's protocol.
process - Handles all basic functions of an AO server. Characters, Messages, Music, etc.
modules - Extra layer of logic that expands upon
]]

local RECEIVEMAX = 2048
local SENDMAX = 2048

local server = {
	software = "AOLS2",
	version = "alpha",

	kill=false,

	clients={},

	process = dofile(path.."server/process.lua"),

	protocols={
		dofile(path.."server/protocols/ao2.lua"),
		dofile(path.."server/protocols/websocket.lua"),
	},
	modules={}, --TODO: Make this adjustable via file. --Wait why have modules here if process is the one using them?

}

function server:start()
	self.socket = socket.tcp()
	self.socket:setoption("reuseaddr",true)
	self.socket:setoption("keepalive",false) --Prevent random disconnects, hopefully.
	self.socket:settimeout(0)

	assert(self.socket:bind(config.ip,config.port))
	local ip,port = self.socket:getsockname()
	verbosewrite("Bound to "..ip..":"..port..".\n")

	assert(self.socket:listen(config.maxplayers))
	print("Server is now listening for up to "..config.maxplayers.." players.")

	self.process:start(server)
	verbosewrite("Started process.\n")

	local modules = {}
	for i,v in ipairs(modules) do
		local s, module = pcall(dofile,path.."server/modules/"..v)
		if s then
			modules[#modules+1] = module
		end
	end
end

--TODO: Fix poor client close handling.

function server:update()
	repeat
		local client = self.socket:accept()
		if client then
			client:settimeout(0)
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
