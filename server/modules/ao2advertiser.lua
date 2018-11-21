local socket = require "socket"
masterserver = {}

function masterserver:connect(ip,port)
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

function masterserver:update()
	local client = masterserver.client
	if not client then return end
	
	local buffer = ""
	repeat
		local c,err = client:receive(1)
		if err == "closed" and os.time() > masterserver.lastupdate+60*20 then
			print("Connection with masterserver was closed!")
			masterserver:connect(mservip,mservport)
			masterserver.lastupdate = os.time()
		end
	until not c
end

function masterserver:makeHeartbeat()
	local heartbeat = "SCC#"..mservport.."#"..servname.."#"..servdesc.."#AOls#%"
	masterserver.heartbeat = heartbeat
end