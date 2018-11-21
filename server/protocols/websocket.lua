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


function getbytes(str)
	local t = {}
	for i=1,#str do
		table.insert(t,string.byte(str:sub(i,i)))
	end
	return unpack(t)
end


function wspayloaddecode(dat)
	if dat == "" or not dat then return nil end
	local p = 0

	local byteA,byteB = getbytes(dat:sub(p+1,p+2))
	--local byteB = string.byte(dat:sub(p+2,p+2))
	local FIN = bit.band(byteA,0x80) ~= 0
	local OPCODE = bit.band(byteA,0x0F)
	local MASKED = bit.band(byteB,0x80) ~= 0
	local LENGTH = bit.band(byteB,0x7F)
	p = p + 2
	if LENGTH == 126 then
		local a,b = getbytes(dat:sub(p+1,p+2))
		LENGTH = bit.bor(bit.lshift(a,8),b)
		p = p + 2
	elseif LENGTH == 127 then

		local a,b,c,d,e,f,g,h = getbytes(dat:sub(p+1,p+8))
		--Lua doesn't support 64-bit integers.
		LENGTH = bit.bor(bit.lshift(e,24),bit.lshift(f,16),bit.lshift(g,8),h)
		p = p + 8
	end
	local MASKKEY
	if MASKED then
		local a,b,c,d = getbytes(dat:sub(p+1,p+4))
		MASKKEY = {a,b,c,d}
		--MASKKEY = bit.bor(bit.lshift(a,24),bit.lshift(b,16),bit.lshift(c,8),d)
		p = p + 4
	end
	local PAYLOAD = dat:sub(p+1,p+LENGTH)

	local data = ""
	if MASKED then
		for i=1,LENGTH do
			local j = (i-1) % 4 + 1
			local byte = string.byte(PAYLOAD:sub(i,i))
			if byte then
				data = data .. string.char(bit.bxor(byte,MASKKEY[j]))
			end
		end
	else
		data = PAYLOAD
	end
	return data,OPCODE,MASKED,FIN
end

function wspayloadencode(dat,opcode,masked,fin)
	local encoded = ""

	local OPCODE = opcode or 1
	local byteA = OPCODE
	if fin then byteA = bit.bor(byteA,0x80) end
	encoded = encoded .. string.char(byteA)

	local byteB = 0
	local bytes = {}
	if masked then byteB = bit.bor(byteB,0x80) end

	if #dat < 126 then
		byteB = bit.bor(byteB,#dat)
	elseif #dat < 0xFFFF then
		byteB = bit.bor(byteB,126)
		table.insert(bytes,bit.rshift(#dat,8))
		table.insert(bytes,bit.band(#dat,0xFF))
	else
		byteB = bit.bor(byteB,127)
		table.insert(bytes,bit.band(bit.rshift(#dat,24),0xFF))
		table.insert(bytes,bit.band(bit.rshift(#dat,16),0xFF))
		table.insert(bytes,bit.band(bit.rshift(#dat,8),0xFF))
		table.insert(bytes,bit.band(#dat,0xFF))
	end

	local bytechars = ""
	for i=1,#bytes do bytechars = bytechars .. string.char(bytes[i]) end
	encoded = encoded .. string.char(byteB) .. bytechars

	if masked then
		local data = ""
		local MASKKEY = {math.random(0,0xFF),math.random(0,0xFF),math.random(0,0xFF),math.random(0,0xFF)}
		for i=1,#MASKKEY do
			encoded = encoded .. string.char(MASKKEY[i])
		end
		for i=1,#dat do
			local j = (i-1) % 4 + 1
			data = data .. string.char(bit.bxor(string.byte(dat:sub(i,i)),MASKKEY[j]))
		end
		encoded = encoded..data
	else
		encoded = encoded..dat
	end

	return encoded
end
