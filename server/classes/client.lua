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
	if self.socket then
		self.socket:send(msg,1,#msg)
	end
end

function Client:receive(bytes)
	if not self.socket then return end

	local dat,err = self.socket:receive(bytes)
	--Automatically close this client if socket is closed.
	if err == "closed" then
		self:close()
	end
	return dat, err
end

function Client:close(...)
	if not self.socket then return end --Can't close a client twice :P

	self.process:disconnect(self)

	if config.monitor then
		print("Closed connection to "..self:getAddress())
	end

	if self.protocol then
		self.protocol:close(self)
		self.protocol = nil
	end

	self.socket:close()
	self.socket = nil
end


function Client:bufferraw(msg)
	self.buffer = self.buffer .. msg
end
function Client:send(...)
	if not self.socket then return end

	self.protocol:send(self,self.process,...)
end


function Client:getAddress()
	return tostring(self.ip)..":"..tostring(self.port)
end

return Client
