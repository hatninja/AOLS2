--Websocket wrapper implementation.
local websocket = {
	guid = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
	
}

local mime = require("mime")
local sha1 = dofile(path.."server/libraries/sha1.lua")

function websocket:detect(client,process)
	if #client.received == 0 or data:sub(1,3) ~= "GET" then return end

	if client.received:find("websocket") then --Client is using websocket, we need to send a handshake back!
		print(client.received)
		local key = data:match("Sec%-WebSocket%-Key: (%S+)")
		if key then
			local accept = mime.b64(sha1.binary(key..self.guid)):sub(1,-2).."="
			
			local handshake = "HTTP/1.1 101 Switching Protocols\r\n"
			.."Upgrade: websocket\r\n"
			.."Connection: Upgrade\r\n"
			.."Sec-WebSocket-Accept: "..accept.."\r\n\r\n"
			
			client:sendraw(handshake)
			client.websocket = true
			client.received = ""
		end
	end
end

function websocket:update(client,process)
	--[[		if client.websocket then
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
						]]
end


function websocket:getbytes(str)
	local t = {}
	for i=1,#str do
		table.insert(t,string.byte(str:sub(i,i)))
	end
	return unpack(t)
end


function websocket:decode(dat)
	if not bit then return end
	if #dat < 4 then return nil end

	local p = 0

	local byteA,byteB = self:getbytes(dat:sub(p+1,p+2))

	local FIN = bit.band(byteA,0x80) ~= 0
	local OPCODE = bit.band(byteA,0x0F)
	local MASKED = bit.band(byteB,0x80) ~= 0
	local LENGTH = bit.band(byteB,0x7F)
	p = p + 2
	if LENGTH == 126 then
		local a,b = self:getbytes(dat:sub(p+1,p+2))
		LENGTH = bit.bor(bit.lshift(a,8),b)
		p = p + 2
		
	elseif LENGTH == 127 then 
		local a,b,c,d,e,f,g,h = self:getbytes(dat:sub(p+1,p+8))
		LENGTH = bit.bor(bit.lshift(e,24),bit.lshift(f,16),bit.lshift(g,8),h) --Lua doesn't use 64-bit integers
		p = p + 8
	end
	
	local MASKKEY
	if MASKED then
		local a,b,c,d = self:getbytes(dat:sub(p+1,p+4))
		MASKKEY = {a,b,c,d}
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

function websocket:encode(dat,opcode,masked,fin)
	if not bit then return end
	
	local encoded = ""

	local OPCODE = opcode or 1
	local byteA = OPCODE
	if fin then byteA = bit.bor(byteA,0x80) end
	encoded = encoded .. string.char(byteA)

	local byteB = 0
	local bytes = {}
	if masked then byteB = bit.bor(byteB,0x80) end

	--Convert length into string data
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
