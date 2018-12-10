local socket = require "socket"
local process = ...

local ao2advertiser = {}
function ao2advertiser:init(process)
end

function ao2advertiser:connect(ip,port)
	if not config.ao2advertise then return end
	print("Connecting to the master server...")
	local client = socket.connect(ip,port)
	if client then
		client:settimeout(0)
		print("Connected to master server, now advertising.")
		
		masterserver:makeHeartbeat()
		customsend(client,masterserver.heartbeat)

		masterserver.client = client
		
		masterserver.lastupdate = os.time()
	else
		print("Could not connect to master server!")
	end
end

function ao2advertiser:update()
	if not config.ao2advertise then return end
	local c,err = client:receive(1)
	if err == "closed" and os.time() > self.lastupdate+60*20 then
		process:print("Connection with masterserver was closed!")
		self:connect(config.ao2msip,config.ao2msport)
		self.lastupdate = os.time()
	end
end

function ao2advertiser:makeHeartbeat()
	local heartbeat = "SCC#"..mservport.."#"..servname.."#"..servdesc.."#AOls#%"
	masterserver.heartbeat = heartbeat
end

return ao2advertiser