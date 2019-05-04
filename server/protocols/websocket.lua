--Websocket wrapper implementation.
--Documentation used: https://tools.ietf.org/html/rfc6455
local websocket = {
	name = "WebSocket",
	guid = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11",
	
	received = {},
	protocol = {},
}

local mime = require("mime")
local sha1 = dofile(path.."server/libraries/sha1.lua")

function websocket:detect(client,process)
	if not bit then return end

	if #client.received == 0 or client.received:sub(1,3) ~= "GET" then return end

	if client.received:find("websocket") then --Client is using websocket, we need to send a handshake back!
		local key = client.received:match("Sec%-WebSocket%-Key: (%S+)")
		if key then
			local accept = mime.b64(sha1.binary(key..self.guid)):sub(1,-2).."="
			
			local handshake = "HTTP/1.1 101 Switching Protocols\r\n"
			.."Upgrade: websocket\r\n"
			.."Connection: Upgrade\r\n"
			.."Sec-WebSocket-Accept: "..accept.."\r\n\r\n"

			client:sendraw(handshake)

			client.received = ""
			self.received[client] = ""

			client.websocket = true
			
			client.protocol = self
			return true
		end
	end
end

function websocket:update(client,process)
	if not self.received[client] then return end
	
	local server = process.server
	repeat
		local data, opcode, masked, fin, packetlength = self:decode(client.received)
		if data then
			if opcode < 3 then
				self.received[client] = self.received[client] .. data
				client.received = client.received:sub(packetlength+1,-1)
			elseif opcode == 8 then --Client wants to close
				process:send(client,"CLOSE")
				return
			elseif opcode == 9 then --PING
				local pong = self:encode(data,10,false,true)
				client:sendraw(pong)
			end
		end
	until not data

	--Temporarily use self.received[client] as client.received
	local received = client.received
	client.received = self.received[client]

	--Update protocols just like in server.lua
	if not self.protocol[client] then
		for k,protocol in pairs(server.protocols) do
			if protocol:detect(client,process) then
				self.protocol[client] = protocol
				client.protocol = self
				break
			end
		end
	else
		self.protocol[client]:update(client,process)
	end

	self.received[client] = client.received
	client.received = received

	--Convert client's send buffer to a websocket text packet.
	if self.protocol[client] then
		if #client.buffer > 0 then
			if self.protocol[client].name == "AO2" then --WebAO compatibility hack.
				repeat
					local st,en = client.buffer:find("%%")
					if st then
						local sendpacket = self:encode(client.buffer:sub(1,st),1,false,true)
						client:sendraw(sendpacket)

						client.buffer = client.buffer:sub(en+1,-1)
					end
				until not st
				client.buffer = ""
			else
				client.buffer = self:encode(client.buffer,1,false,true)
			end

			--[[local dat,opcode,masked,fin = self:decode(client.buffer)
			print("WS SENT",
			"'"..tostring(dat).."'",
			"LENGTH: "..tostring(dat and #dat),
			"OPCODE: "..tostring(opcode),
			"MASK: "..tostring(masked),
			"FIN: "..tostring(fin))]]
		end
	end
end

function websocket:send(client,process, call,data)
	if self.protocol[client] then
		self.protocol[client]:send(client,process, call,data)
	end
end

function websocket:close(client)
	if self.protocol[client] then
		self.protocol[client]:close(client)
	end
	self.received[client] = nil
	self.protocol[client] = nil
end


function websocket:getbytes(str)
	if type(str) ~= "string" then return end
	local t = {0,0,0,0,0,0,0,0}
	for i=1,#str do
		t[i] = string.byte(str:sub(i,i))
	end
	return unpack(t)
end

function websocket:decode(dat)
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
	return data,OPCODE,MASKED,FIN,p+LENGTH
end

function websocket:encode(dat,opcode,masked,fin)
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

return websocket