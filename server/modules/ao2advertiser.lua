local socket = require "socket"
local process = ...

local ao2advertiser = {
	name = "AO2",

	cooldown = 60*20, --Time (In seconds) to reconnect if connection was lost.
}
function ao2advertiser:init(process)
	self:connect(config.ao2msip,config.ao2msport)
	process:registerCallback(self,"update", 0,self.update)
	process:registerCallback(self,"close", 0,self.close)
end

function ao2advertiser:connect(ip,port)
	if not config.ao2advertise then return end

	self:print("Connecting to the master server...")

	local client = socket.connect(ip,port)
	if client then
		client:settimeout(0)
		self.client = client

		local heartbeat = "SCC#"..tostring(config.port).."#"..tostring(config.name).."#"..tostring(config.desc).."#"..tostring(process.server.software).."#%"
		client:send(heartbeat,1,#heartbeat)
		self.lastupdate = process.time

		self:print("Connected to master server, now advertising.")

	else
		self:print("Could not connect to master server!")
	end
end

function ao2advertiser:update()
	if not config.ao2advertise then return end
	repeat
		local c,err = self.client:receive(1)
		if err == "closed" and process.time > self.lastupdate+60*20 then
			self:print("Connection with masterserver was closed!")
			self:connect(config.ao2msip,config.ao2msport)
			self.lastupdate = process.time
		end
	until not c
end

function ao2advertiser:close()
	if self.client then
		self.client:close()
		self.client = nil
	end
end

return ao2advertiser
