-- For websocket support
local guid = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
local mime = require("mime")
local sha1 = dofile(path.."sha1.lua")

local clientList = {}

function buffersend(client,msg)
	if client and clientList[client] then
		clientList[client].send = (clientList[client].send or "") .. msg
	end
end

function loop()
	repeat
		local client = server:accept()
		if client then
			client:settimeout(0)

			clientList[client] = ({
				socket=client,
				send="",
				received="",
				open=false,
			})
		end
	until not client

	for i,v in pairs(clientList) do
		local client = v
		if client and client.socket then			
			--RECEIVE
			local data = ""
			repeat
				local c,err = client.socket:receive(1)
				if c then data=data .. c end
				if err == "closed" or #data > 4000 then --Way too massive for anyone to expect from a client!
					doclosed(client.socket)
					clientList[i] = nil
					break
				end
			until not c --Always check if your loops are correct. I thought "client:receive(1)" was blocking like mad!
			
			if #data>0 then --Only open if data is received

			--Hacky WebSockets Support
			if data:sub(1,3) == "GET" and data:find("websocket") then --Client is using websocket, we need to send a handshake back!
				local key = data:match("Sec%-WebSocket%-Key: (%S+)")
				if key then
					local accept = mime.b64(sha1.binary(key..guid)):sub(1,-2).."="

					local handshake = "HTTP/1.1 101 Switching Protocols\r\n"
					handshake = handshake.."Upgrade: websocket\r\n"
					handshake = handshake.."Connection: Upgrade\r\n"
					handshake = handshake.."Sec-WebSocket-Accept: "..accept.."\r\n\r\n"

					customsend(client.socket,handshake)
					client.websocket = true
					data = ""
				end
			end
			if client.websocket then
				local dat,opcode,masked,fin = wspayloaddecode(data)
				if dat then
					if opcode < 3 then
						data = dat
					elseif opcode == 8 then --Client wants to close
						doclosed(client.socket)
						clientList[i] = nil
					elseif opcode == 9 then --PING
						customsend(client.socket,wspayloadencode(dat,10,false,true)) --Send PONG
					end
					--print("GOT","'"..dat.."'","OPCODE: "..tostring(opcode),"Masked: "..tostring(masked),"FIN: "..tostring(fin))
				end
			end
			
			client.received=client.received .. data
			
			--Open clients here, because we want to keep it clean for websocket handshake.
			if not client.open then
				doaccept(client.socket)
				client.open = true
			end

			end
			
			--PROCESS
			repeat
				local st,en = client.received:find("%%")
				if st then
					local subcommand = client.received:sub(1,st-1)
					
					local suc,err = pcall(dosubcommand, client.socket,subcommand)
					if not suc then
						print("Client["..tostring(client).."] Error with: "..subcommand)
						print(err)
					end

					client.received = client.received:sub(en+1,-1)
				end
			until not st
			
			--SEND
			if client.websocket then
				repeat --Send by subcommands, webAO doesn't recognize multiple in one message.
					local st,en = client.send:find("%%")
					if st then
						local subcommand = client.send:sub(1,st)
						
						local message = wspayloadencode(subcommand,1,false,true)
						customsend(client.socket,message)

						
						local dat,opcode,masked,fin = wspayloaddecode(message)
						--print("SENT","'"..tostring(dat).."'","LENGTH: "..tostring(#dat),"OPCODE: "..tostring(opcode),"Masked: "..tostring(masked),"FIN: "..tostring(fin))
						
						client.send = client.send:sub(en+1,-1)
					end
				until not st
			else
				local data = client.send:sub(1,2048)
				if #data > 0 then
					customsend(client.socket,data)
				end
				client.send = client.send:sub(2048,-1)
			end
		end
	end
	
	doupdate(rate)
end