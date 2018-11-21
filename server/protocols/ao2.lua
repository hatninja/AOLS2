--[[Internal protocol is the interface through which the server can interact with any client, provided their protocol is supported.
To support a protocol, a layer must be implemented that can translate between the client's protocol and internal protocol.

Client > INFO_REQ
Server > INFO_SEND

Client > JOIN_REQ
Message that indicates that the client wants to join. You can respond with ALLOW_JOIN or DENY_JOIN
Server > JOIN_INIT
Server > JOIN_DENY (Reason)

Client > CHAR_REQ (Character name)
Server > CHAR_PICK (Character name)
Server > CHAR_DENY (Character name)

Bi-directional > OOC (Name) (Message)

Bi-directional > IC (Dialogue) (Character) (Emote Name) {pre_emote, sfx_name, sfx_delay} (Side) (Interjection) (Item Image Name)

Bi-directional > CHANGE_BG (Background Name)
Bi-directional > CHANGE_FG (Boolean)
Bi-directional > CHANGE_HP (Team) (Amount)

Bi-directional > PLAY_MUSIC (Music Name) (Activator Name)
Omit name to change music without notifying.

Bi-directional > PLAY_SOUND (Sound Name) (Activatior Name)
Omit name to play sound without notifying.

ADD_ITEM
DELETE_ITEM
EDIT_ITEM
LIST_ITEMS
]]

--The Attorney Online 1.x/2.x protocol. This implementaton also has extensions for the Case Cafe client.
--The AO protocol documentation can be found here:
--https://github.com/AttorneyOnline/AO2Protocol/blob/master/Attorney%20Online%20Client-Server%20Network%20Specification.md
local AO2 = {
	name = "AO2"
}

function AO2:detect(client,process)
	--Simple timer, attempt to connect if nothing sent. AO2 really needs a handshake...
	if true then
		client.protocol = self
		client.protocol_state = {}
		process:send(client,"INFO_REQ")
		return true
	end
end

--Update a client.
function AO2:update(client,process)
	local st,en = client.received:find("%%")
	if st then
		local subcommand = client.received:sub(1,st-1)
		client.received = client.received:sub(en+1,-1)

		if subcommand:sub(1,1) == "#" then subcommand = subcommand:sub(2,-1) end
		local args = self:split(subcommand,"#")

		--Old logic: #args[1] == 4 or #args[1] == 14 or #args[1] == 16
		--It's most likely encrypted if it has more than two numbers in it.
		--if bit and args[1]:match("^.-%d.-%d") and #args[1] > 2 then
			--args[1] = self:decryptStr(self:hexToString(args[1]), 5)
		--end

		print("CLIENTRAW",encrypted and "("..encrypted..")" or "("..args[1]..")",table.concat(args,", "))

		if args[1] == "HI" or args[1] == "48E0" then
			client.hardwareid = args[2]
		end
		if args[1] == "ID" or args[1] == "493F" then
			client.software = args[2]
			client.version = args[3]
		end

		if args[1] == "askchaa" or args[1] == "615810BC07D139" then
			local characters = process:getCharacters(client)
			client.protocol_state.char_list = characters

			process:send(client,"JOIN_REQ")
		end

		--LOADING
		if client.protocol_state.char_list then
			local loading_done = false

			--[[Loading 1.0]]
			if args[1] == "askchar2" or args[1] == "615810BC07D12A5A" then
				client.software = "AO"
				self:sendCharacterList(client,client.protocol_state.char_list, feature_fastslowload or 1)
			end

			if args[1] == "AN" or args[1] == "41A5" then
				if tonumber(args[2]) and tonumber(args[2])*10 <= #client.protocol_state.char_list then
					self:sendCharacterList(client,client.protocol_state.char_list, tonumber(args[2])+1)
				else
					client:sendraw("EI#1#N&A&1&hi_there.png&#%") --Characters finished, let's move over to evidence,
				end
			end
			if args[1] == "AE" or args[1] == "41AE" then
				client:sendraw("EM#0#No Music#%") --No evidence here, let's go to music.
			end

			--TODO: Implement music in AO loading 1.0
			if args[1] == "AM" or args[1] == "41A6" then
				loading_done = true --Welp, looks like we're done!
			end

			--[[Loading 2.0]]
			if args[1] == "RC" or args[1] == "529E" then
				local characters = process:getCharacters(client)
				self:sendCharacterList(client,characters)

			elseif args[1] == "RM" or args[1] == "5290" then
				client:sendraw("SM#Music#%")

			elseif args[1] == "RD" or args[1] == "5299" then
				loading_done = true
			end

			if loading_done then
				client:sendraw("CharsCheck#0#%") --TODO: Fix WebAO breaking when all values aren't filled.
				client:sendraw("DONE#%")
				--NOTE: Freepick boot with CHAR_PICK, -1 in process or here?
				if feature_freepick then client:sendraw("PV#0#CID#-1#%") end --Boots the player to the scene.
			end
		end

		--Character Picking
		if args[1] == "CC" or args[1] == "43CC" then --I wonder if anyone actually has a version using names instead. Just because #CID# and all...
			local char_id = self:tointeger(args[3])
			self:check(client, char_id)
			if char_id then
				process:send(client,"CHAR_REQ", {
					character = client.protocol_state.char_list[char_id+1]
				})
			end
		end

		if args[1] == "CH" or args[1] == "43C7" then client:sendraw("CHECK#%") end

		if args[1] == "ZZ" or args[1] == "5A37" then
			process:send(client,"MOD_CALL", {
				reason = self:unescape(tostring(args[2]))
			})
		end
		if args[1] == "CT" or args[1] == "43DB" then
			self:check(client,args[2])
			self:check(client,args[3])
			process:send(client,"OOC", {
				name = self:unescape(tostring(args[2])),
				message = self:unescape(tostring(args[3]))
			})
		end
		if args[1] == "MS" or args[1] == "4D90" then
			--Check if all normal arguments are here.
			for i=2,16 do self:check(client,args[i]) end

			local desk = args[2]
			local pre_emote = args[3]
			local character = args[4]
			local emote = args[5]
			local message = args[6]
			local side = args[7]
			local sfx_name = args[8]
			local emote_modifier = self:tointeger(args[9])
			local char_id = self:tointeger(args[10])
			local sfx_delay = self:tointeger(args[11])
			local shout_modifier = self:tointeger(args[12])
			local evidence = self:tointeger(args[13])
			local flip = self:tointeger(args[14])
			local realization = self:tointeger(args[15])
			local text_color = self:tointeger(args[16])

			local showname = args[17] --Comes with CC, good way to detect CC client users.
			if args[17] then client.software = "CC" end

			--Kick client if arguments are invalid.
			self:check(client, desk == "0" or desk == "1" or desk == "chat")
			self:check(client, side == "def" or side == "pro" or side == "jud" or side == "wit" or side == "hld" or side == "hlp")

			self:check(client, emote_modifier and char_id and sfx_delay and shout_modifier and evidence and flip and realization and text_color)
			self:check(client, emote_modifier >= 0 and emote_modifier < 7)
			self:check(client, sfx_delay >= 0)
			self:check(client, shout_modifier >= 0 and shout_modifier < 6)
			self:check(client, evidence >= 0)
			self:check(client, flip == 0 or flip == 1)
			self:check(client, realization == 0 or realization == 1)
			self:check(client, text_color >= 0 and text_color < 7)

			--Convert escaped characters back to normal.
			message = self:unescape(message)

			--Escape carats for internal markdown safety.
			message = message:gsub("%^","^^")

			--Convert case cafe markdown to internal markdown.
			if client.software == "CC" then
				local lastcolors = {text_color}
				local gsubfunc = function(char,code)
					--Get non-color markdowns out of the way.
					if code == "{" then return char.."^t-" end
					if code == "}" then return char.."^t+" end

					--Get corresponding color code.
					local code_color = 0
					if code == "`" then code_color = 1
					elseif code == "|" then code_color = 3
					elseif code == "[" then code_color = 9
					elseif code == "]" then code_color = -9
					elseif code == "(" then code_color = 4
					elseif code == ")" then code_color = -4
					end

					--Now we determine the right markdown needed to match the CC client's functionality.
					local markdown
					if code_color < 4 then --One character markdowns. Disappears on use.
						if code_color ~= lastcolors[#lastcolors] then lastcolors[#lastcolors+1] = code_color
						else lastcolors[#lastcolors] = nil
						end
						markdown = self:colortomarkdown(lastcolors[#lastcolors])
						return char..markdown

					else --Bracket markdowns. Doesn't disappear.
						if code_color > 0 then
							lastcolors[#lastcolors+1] = code_color
							markdown = self:colortomarkdown(lastcolors[#lastcolors])

							return char..markdown..code

						elseif lastcolors[#lastcolors] == code_color then
							lastcolors[#lastcolors] = nil
							markdown = self:colortomarkdown(lastcolors[#lastcolors])

							return char..code..markdown
						end
					end
					return char..code
				end

				message = (" "..message) --A quick hack to make gsubfunc work
				:gsub("^~~","^tc")
				:gsub("\\(%s-)\\","%1<backslash>") --I'm really feelin' it!
				:gsub("([^\\])([%`%|%[%]%(%)])",gsubfunc)
				:gsub("\\",""):gsub("<backslash>","\\")
				:sub(2,-1)
			end

			--Add internal markdown to the message.
			if realization == 1 then message = "^er" .. message end
			if text_color ~= 0 then
				message = self:colortomarkdown(text_color) .. message
			end

			--Update values for processing
			if desk == "chat" then
				desk = false
				if side == "def" or side == "pro" or side == "wit" then desk = true end
			elseif desk == "1" then
				desk = true
			else
				desk = false
			end

			if side == "wit" then side = 0
			elseif side == "def" then side = 1
			elseif side == "pro" then side = 2
			elseif side == "jud" then side = 3
			elseif side == "hld" then side = 4
			elseif side == "hlp" then side = 5
			end

			--Doesn't hurt to remove this silly restriction, eh?
			--if shout_modifier ~= 0 then emote_modifier = 2 end

			local zoom = (emote_modifier > 4)
			if emote_modifier == 0 or emote_modifier > 4 or pre_emote == "-" or zoom then pre_emote = nil end

			if zoom then --Send BG zoom end
			end
			if desk then --Send FG status
			end

			process:send(client,"IC", {
				dialogue=message,
				character=character,
				name=showname,

				emote=emote,
				pre_emote=pre_emote,

				side=side,
				item=evidence,
			})
		end

		if args[1] == "MC" or args[1]  == "4D90" then
		end

		if args[1] == "PE" or args[1] == "507C" then --Add evidence
		end
	end
end

--Messages sent from server to clients
function AO2:send(client,process, call,data)
	if call == "INFO_SEND" then
		client:sendraw("decryptor#34#%")
		client:sendraw("ID#0#"..(data.software).."#"..(data.version).."#%")
		client:sendraw("PN#"..(data.players).."#"..(data.maxplayers).."#%")
		client:sendraw("FL#yellowtext#customobjections#flipping#deskmod#modcall_reason#cc_customshownames#%")--noencryption#fastloading
	end
	if call == "JOIN_ALLOW" then
		client:sendraw("SI#1#0#0#%") --Must have at least one character to initate loading. Loading does not rely on this anyway.
	end
	if call == "JOIN_DENY" then end

	if call == "CHAR_PICK" then
		local char_id
		local characters = client.protocol_state.char_list
		if characters then
			for i,v in ipairs(characters) do
				if v == data.character then
					char_id = i
					break
				end
			end
			if not char_id then --Send new list with the specific character added.
				char_id = #characters+1
				characters[char_id] = data.character
				self:sendCharacterList(client,characters)
			end
			client:sendraw("PV#0#CID#"..(char_id-1).."#%")
		end
		if args[2] == -1 then
			client:sendraw("PV#0#CID#-1#%")
		end
	end

	if call == "OOC" then
		client:sendraw("CT#"..self:escape(data.name).."#"..self:escape(data.message).."#%")
	end
end

--TODO: Get rid of this and replace with return statements.
--Kick the client if statement is false.
function AO2:check(client,statement)
	if not statement then
		print("Failed check, closing client!")
		client.socket:close()
		return false
	end
	return true
end

function AO2:tointeger(num)
	local num = tonumber(num)
	if num and math.floor(num) == num then
		return num
	end
end

function AO2:split(input,delimit)
	local t = {}
	local string = tostring(input)
	local delimiter = tostring(delimit) or ""
	if delimiter and delimiter ~= "" then
		while string:find(delimiter) do
			local beginning, ending = string:find(delimiter)
			table.insert(t,string:sub(1,beginning-1))
			string = string:sub(ending+1)
		end
		if not string:find(delimiter) then
			if string ~= "" then
				table.insert(t,string)
			end
		end
	else
		for i = 1, #string do
			table.insert(t,string:sub(i,i))
		end
	end

	return t
end

function AO2:escape(str)
	return str:gsub("\\","\\\\") --Remove if AO print was not accurate.
	:gsub("%#","<num>")
	:gsub("%$","<dollar>")
	:gsub("%%","<percent>")
	:gsub("%&","<and>")
end

function AO2:unescape(str)
	return str:gsub("\\\\","\\") --Remove if AO print was not accurate.
	:gsub("<num>","#")
	:gsub("<dollar>","$")
	:gsub("<percent>","%")
	:gsub("<and>","&")
end

function AO2:colortomarkdown(color)
	if color == 0 then return "^cw"
	elseif color == 1 then return "^cg" --Green
	elseif color == 2 then return "^cr" --Red
	elseif color == 3 then return "^co" --Orange
	elseif color == 4 then return "^cb" --Blue
	elseif color == 5 then return "^cy" --Yellow
	elseif color == 6 then return "^cs" --Secret (Rainbow)
	--CC colors
	elseif color == 7 then return "^cp" --Pink
	elseif color == 8 then return "^cc" --Cyan
	elseif color == 9 then return "^ce" --Grey
	end
end

function AO2:hexToString(hex)
	print("HEX",hex)
	local str = ""
	for i=1,math.ceil(#hex/2)*2,2 do
		str = str..string.char( tonumber(hex:sub(i,i+1),16) )
	end
	return str
end

--Fantacrypt algorithm.
local C1 = 53761
local C2 = 32618
function AO2:decryptStr(str, key)
	local k = key
	local final = ""
	for i=1,#str do
		local char = string.byte(str:sub(i,i))
		final = final..string.char( bit.bxor( char, bit.rshift(k,8) ) % 256 )
		k = C2 + (char + k) * C1
	end
	return final
end

--Character list shenanigans.
--TODO: Fix AO loading
function AO2:sendCharacterList(client,t,page)
	local charlist = ""
	local char_table = {}
	if not page and not client.protocol_state.char_list then
		for i,v in ipairs(t) do
			charlist = charlist .. self:escape(v) .. "#"
			char_table[#char_table+1] = v
		end
		client:sendraw("SC#"..charlist.."%")
	else
		local charlist = ""
		for i3=1,(page == true and #t or 10) do
			local id = ((page == true and 1 or page)-1)*10+i3
			if t[id] then
				charlist = charlist .. id-1 .. "#" .. self:escape(t[id]) .."&".."&0&&&0&#"
			else
				break
			end
		end
		client:sendraw("CI#"..charlist.."%")
	end
end

--Update character list
function AO2:updateCharacterList(client,chars,ids)
end

function AO2:remove(client,chars)
end

return AO2
