--The Attorney Online 1.x/2.x protocol. This implementaton also has extensions for the Case Cafe client.
--The AO protocol documentation can be found here:
--https://github.com/AttorneyOnline/AO2Protocol/blob/master/Attorney%20Online%20Client-Server%20Network%20Specification.md
local AO2 = {
	name = "AO2",

	input = {},

	output = {},
}

AO2.input["HI"] = function(self,client,process,call, hardwareid)
	client.hardwareid = hardwareid
end

AO2.input["ID"] = function(self,client,process,call, software,version)
	client.software = software
	client.version = version
end

AO2.input["askchaa"] = function(self,client,process,call)
	local characters = process:getCharacters(client)
	client.protocol_state.char_list = characters

	process:send(client,"JOIN_REQ")
end

--[[Loading 1.0]]
AO2.input["askchar2"] = function(self,client,process,call)
	if not client.protocol_state.char_list then return end
	client.software = "AO"
	self:sendCharacterList(client,client.protocol_state.char_list, feature_fastslowload or 1)
end
AO2.input["AN"] = function(self,client,process,call, page)
	if not client.protocol_state.char_list then return end
	if tonumber(page) and tonumber(page)*10 <= #client.protocol_state.char_list then
		self:sendCharacterList(client,client.protocol_state.char_list, tonumber(page)+1)
	else
		client:sendraw("EI#1#N&A&1&hi_there.png&#%") --Characters finished, let's move over to evidence,
	end
end
AO2.input["AE"] = function(self,client,process,call, page)
	client:sendraw("EM#0#No Music#%") --No evidence here, let's go to music.
end
AO2.input["AM"] = function(self,client,process,call, page) --TODO: Implement music in AO loading 1.0
	--Welp it looks like we're done!

	client:sendraw("CharsCheck#0#%") --TODO: Fix WebAO breaking when all values aren't filled.
	client:sendraw("DONE#%")
	--NOTE: Freepick boot with CHAR_PICK, send -1 to process or keep it here?
	if feature_freepick then client:sendraw("PV#0#CID#-1#%") end --Boots the player to the scene.

end

--[[Loading 2.0]]
AO2.input["RC"] = function(self,client,process,call)
	if not client.protocol_state.char_list then return end
	self:sendCharacterList(client,client.protocol_state.char_list)
end
AO2.input["RM"] = function(self,client,process,call)
	client:sendraw("SM#Yes Music#%")
end
AO2.input["RD"] = AO2.input["AM"] --It's the same finish code, for now


AO2.input["CC"] = function(self,client,process,call, playerid,id) --I wonder if anyone actually has a version using names instead. Just because #CID# and all...
	local char_id = self:tointeger(id)
	if not char_id then return end

	process:send(client,"CHAR_REQ", {
		character = client.protocol_state.char_list[char_id+1]
	})
end

AO2.input["ZZ"] = function(self,client,process,call, reason)
	process:send(client,"MOD_CALL", {
		reason = self:unescape(tostring(reason))
	})
end

AO2.input["CH"] = function(self,client,process,call)
	client:sendraw("CHECK#%")
end

AO2.input["CT"] = function(self,client,process,call, name,message)
	if not name or not message then return end
	process:send(client,"OOC", {
		name = self:unescape(tostring(name)),
		message = self:unescape(tostring(message))
	})
end

AO2.input["MS"] = function(self,client,process,call, ...)
	local desk, pre_emote, character, emote, message, side, sfx_name,
		  emote_modifier, char_id, sfx_delay, shout_modifier, evidence,
		  flip, realization, text_color, cc_showname = ...

	emote_modifier = self:tointeger(emote_modifier)
	char_id = self:tointeger(char_id)
	sfx_delay = self:tointeger(sfx_delay)
	shout_modifier = self:tointeger(shout_modifier)
	evidence = self:tointeger(evidence)
	flip = self:tointeger(flip)
	realization = self:tointeger(realization)
	text_color = self:tointeger(text_color)

	--Make sure the message is safe.
	if not (desk and pre_emote and character and emote and message and side and sfx_name
	and emote_modifier and char_id and sfx_delay and shout_modifier and evidence
	and flip and realization and text_color) then return end
	if not (desk == "0" or desk == "1" or desk == "chat") then return end
	if not (side == "def" or side == "pro" or side == "jud" or side == "wit" or side == "hld" or side == "hlp") then return end
	if not (emote_modifier >= 0 and emote_modifier < 7) then return end
	if not (sfx_delay >= 0) then return end
	if not (shout_modifier >= 0 and shout_modifier < 6) then return end
	if not (evidence >= 0) then return end
	if not (realization == 0 or realization == 1) then return end
	if not (text_color >= 0 and text_color < 7) then return end

	if cc_showname then client.software = "CC" end

	message = self:unescape(message)

	--Escape carats for internal markdown safety.
	--[[message = message:gsub("%^","^^")

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
	end]]

	--Update values for processing
	if desk == "chat" then
		desk = false
		if side == "def" or side == "pro" or side == "wit" then desk = true end
	elseif desk == "1" then
		desk = true
	else
		desk = false
	end

	local zoom = (emote_modifier > 4)

	if side == "wit" then side = 0
	elseif side == "def" then side = 1
	elseif side == "pro" then side = 2
	elseif side == "jud" then side = 3
	elseif side == "hld" then side = 4
	elseif side == "hlp" then side = 5
	else side = 0
	end

	--Doesn't hurt to remove this silly restriction, eh?
	--if shout_modifier ~= 0 then emote_modifier = 2 end

	if emote_modifier == 0 or emote_modifier > 4 or pre_emote == "-" or zoom then pre_emote = nil end

	process:send(client,"IC", {
		dialogue=message,
		character=character,
		name=cc_showname,

		emote=emote,
		pre_emote=pre_emote,

		side=side,
		item=evidence,
	})

	--No server is complete without tons of hours spent on MS!
end

--Encrypted table
AO2.input["48E0"] = AO2.input["HI"]
AO2.input["493F"] = AO2.input["ID"]
AO2.input["615810BC07D139"] = AO2.input["askchaa"]
AO2.input["615810BC07D12A5A"] = AO2.input["askchar2"]
AO2.input["41A5"] = AO2.input["AN"]
AO2.input["41AE"] = AO2.input["AE"]
AO2.input["41A6"] = AO2.input["AM"]
AO2.input["529E"] = AO2.input["RC"]
AO2.input["5290"] = AO2.input["RM"]
AO2.input["5299"] = AO2.input["RD"]
AO2.input["43CC"] = AO2.input["CC"]
AO2.input["5A37"] = AO2.input["ZZ"]
AO2.input["43C7"] = AO2.input["CH"]
AO2.input["43DB"] = AO2.input["CT"]
AO2.input["4D90"] = AO2.input["MS"]
AO2.input["4D80"] = AO2.input["MC"]
AO2.input["507C"] = AO2.input["PE"]


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

		print("CLIENTRAW",encrypted and "("..encrypted..")" or "("..args[1]..")",table.concat(args,", "))

		if self.input[args[1]] then
			self.input[args[1]](self,client,process,unpack(args))
			--Maybe have returns send messages for invalid messages.
		else
			print("Unknown message: "..args[1])
		end

		--client:sendraw("SC#%") insta-closes the client, neato!
	end
end

--Messages sent from server to clients
function AO2:send(client,process, call,data)
	if call == "INFO_SEND" then
		client:sendraw("decryptor#34#%")
		client:sendraw("ID#0#"..(data.software).."#"..(data.version).."#%")
		client:sendraw("PN#"..(data.players).."#"..(data.maxplayers).."#%")
		client:sendraw("FL#yellowtext#customobjections#flipping#deskmod#fastloading#modcall_reason#cc_customshownames#%")--noencryption
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
				self:updateCharacterList(client,characters)
			end
			client:sendraw("PV#0#CID#"..(char_id-1).."#%")
		end
		if data.character == -1 then
			client:sendraw("PV#0#CID#-1#%")
		end
	end

	if call == "OOC" then
		client:sendraw("CT#"..self:escape(data.name).."#"..self:escape(data.message).."#%")
	end
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
	if not page then
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

return AO2
