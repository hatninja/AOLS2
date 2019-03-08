--Client, handles and stores everything related to a client connection.

local Client = {}
Client.__index=Client

function Client:new(...)
	local t = {}
	self.init(t,...)
	return setmetatable(t,self)
end

function Client:init(socket, process)
	socket:settimeout(0)

	self.socket = socket
	self.process = process

	self.buffer = ""
	self.received = ""

	self.ip, self.port = socket:getpeername()
end


function Client:sendraw(msg)
	self.socket:send(msg,1,#msg)
end

function Client:receive(bytes)
	return self.socket:receive(bytes)
end

function Client:close(...)
	if self.protocol then
		self.protocol:close(self)
	end
	self.socket:close()
end


function Client:bufferraw(msg)
	self.buffer = self.buffer .. msg
end
function Client:send(...)
	self.protocol:send(self,self.process,...)
end


function Client:getAddress()
	return tostring(self.ip)..":"..tostring(self.port)
end

return Client