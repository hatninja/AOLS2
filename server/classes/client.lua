--Client, handles and stores everything related to a client connection.
local Client = {}
Client.__index=Client

function Client:new(...)
	local t = {}
	self.init(t,...)
	return setmetatable(t,self)
end

function Client:init(socket,process)
	socket:settimeout(0)

	self.socket = socket
	self.process = process

	self.buffer = ""
	self.received = ""

	self.ip, self.port = socket:getpeername()
end

--[[Raw messages]]
function Client:sendraw(msg)
	if self:isClosed() then return end

	self.socket:send(msg,1,#msg)
end
function Client:receive(bytes)
	if self:isClosed() then return end

	local str = ""
	repeat
		local dat,err = self.socket:receive(1)
		if dat then
			str=str..dat
		end
		if err == "closed" then
			self:close()
		end
	until not dat or #str == bytes

	return #str > 0 and str, err
end

function Client:bufferraw(msg)
	self.buffer = self.buffer .. msg
end

--[[Handling]]
function Client:update()
	if self.protocol then
		self.protocol:update(self,self.process)
	end
end

function Client:close(...)
	if self:isClosed() then return end --Can't close a client twice :P

	self:sendraw(self.buffer) --Send last data before closing connection.

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

function Client:isClosed()
	return not self.socket
end


--[[Protocol Layer]]
function Client:send(...)
	if self:isClosed() then return end

	if self.protocol then
		self.protocol:send(self,self.process,...)
	end
end

--[[Miscellaneous]]
function Client:getAddress()
	return tostring(self.ip)..":"..tostring(self.port)
end

return Client
