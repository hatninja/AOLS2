--The Attorney Online 1.x/2.x protocol. Supports up to 2.9.1.
--The AO protocol documentation can be found here:
--https://github.com/AttorneyOnline/docs/blob/master/docs/development/network.md
local AO2 = {
	name = "AO2",

	input = {},
	output = {},

	state = {},
}

function AO2:detect(client,process) --Simple timer, attempt to connect if nothing sent. AO2 really needs a handshake...
	if not self.state[client] then
		self.state[client] = {}
		self.state[client].time = os.clock()
	end

	if os.clock() > self.state[client].time+0.001
	or client.received:find("615810BC07D139")
	or client.received:find("615810BC07D12A5A")
	or client.received:find("48E0")
	or client.received:find("493F")
	or client.received:find("askchaa")
	or client.received:find("askchar2")
	or client.received:find("HI")
	or client.received:find("ID") then
		--1.8 does not send the software packet, so we must assume this by default.
		client.software = "AO"
		client.version = "1.8"

		client.protocol = self
		process:send(client,"INFO_REQ")

		return true
	end
end

function AO2:close(client)
	self.state[client] = nil
end

--Update a client.
function AO2:update(client,process)
	if not self.state[client] then return end

	local st,en = client.received:find("%%")
	if st then
		local subcommand = client.received:sub(1,st-1)
		client.received = client.received:sub(en+1,-1)

		if subcommand:sub(1,1) == "#" then subcommand = subcommand:sub(2,-1) end
		local args = self:split(subcommand,"#")

		if self.input[args[1]] then
			self.input[args[1]](self,client,process,unpack(args))
		else
			print("Unknown message: "..tostring(args[1]),bit and self:decryptStr(self:hexToString(tostring(args[1])),5))
		end

		if config.monitor then
			print("CLIENTRAW",encrypted and "("..encrypted..")" or "("..args[1]..")",table.concat(args,", "))
		end
	end
end

--Incoming connection
AO2.input["HI"] = function(self,client,process,call, hardwareid)
	client.hardwareid = hardwareid
end
AO2.input["ID"] = function(self,client,process,call, software,version)
	client.software = software
	client.version = version

	if client.software == "webAO" then
		self.input["askchaa"](self,client,process,"askchaa")
	end
end

--[[Loading 2.0]]
AO2.input["askchaa"] = function(self,client,process,call)
	local characters =  AO2:makeNameList(process:getCharacters(client),"name")
	self.state[client].char_list = characters

	local music =  AO2:makeNameList(process:getMusic(client),"name")
	self.state[client].music_list = music

	self.state[client].hp = {0,0}

	process:send(client,"JOIN_REQ")
end
AO2.input["RC"] = function(self,client,process,call)
	if not self.state[client].char_list then return end
	process:send(client,"LOAD_CHARS")
	self:sendAssetList(client,"SC",self.state[client].char_list)
end
AO2.input["RM"] = function(self,client,process,call)
	if not self.state[client].music_list then return end
	process:send(client,"LOAD_MUSIC")
	self:sendAssetList(client,"SM",self.state[client].music_list)
end
AO2.input["RD"] = function(self,client,process,call)
	self:finishLoad(client,process)
end
--[[Loading 1.0]]
AO2.input["askchar2"] = function(self,client,process,call) --AO2 specific command. Loading is automatically initated by server itself for AO 1.8
	if not self.state[client].char_list then return end
	process:send(client,"LOAD_CHARS")
	self:sendAssetList(client,"CI",self.state[client].char_list, 1)
end
AO2.input["AN"] = function(self,client,process,call, page)
	if not self.state[client].char_list then return end
	if tonumber(page) and tonumber(page)*10 < #self.state[client].char_list then
		self:sendAssetList(client,"CI",self.state[client].char_list, tonumber(page)+1)
	else
		process:send(client,"LOAD_MUSIC")
		self:sendAssetList(client,"EM",self.state[client].music_list, 1)
		--client:bufferraw("EI#1#N&A&1&hi_there.png&#%") --Characters finished, let's move over to evidence,
	end
end
AO2.input["AE"] = function(self,client,process,call, page)
	--No evidence to send.
end
AO2.input["AM"] = function(self,client,process,call, page) --Used for both so we get the same finishcode.
	if not self.state[client].music_list then return end
	if tonumber(page) and tonumber(page)*10 < #self.state[client].music_list then
		self:sendAssetList(client,"EM",self.state[client].music_list, tonumber(page)+1)
	else
		self:finishLoad(client,process)
	end
end

--[[Connected messages]]
--Choose Character
AO2.input["CC"] = function(self,client,process,call, playerid,id)
	local char_id = self:tointeger(id)
	if not char_id then return end

	process:send(client,"CHAR_REQ", {
		character = tostring(self.state[client].char_list[char_id+1])
	})
end
--Free Character
AO2.input["FC"] = function(self,client,process,call)
end
AO2.input["PW"] = function(self,client,process,call)
end
--Mod Call
AO2.input["ZZ"] = function(self,client,process,call, reason)
	process:send(client,"MOD_CALL", {
		reason = self:unescape(tostring(reason))
	})
end
--Check (Basically a reverse ping-pong)
AO2.input["CH"] = function(self,client,process,call)
	client:bufferraw("CHECK#%")
end
--Chat (OOC)
AO2.input["CT"] = function(self,client,process,call, name,message)
	if not name or not message then return end
	process:send(client,"OOC", {
		name = self:unescape(tostring(name)),
		message = self:unescape(tostring(message))
	})
end
--Message (IC)
AO2.input["MS"] = function(self,client,process,call, ...) --No server is complete without tons of hours spent on MS
	local desk, pre_emote, character, emote, message, side, sfx_name,
		  emote_modifier, char_id, sfx_delay, shout_modifier, evidence,
		  flip, realization, text_color, showname, pair, hscroll, no_interrupt,
		  sfx_looping, shake, frames_shake, frames_flash, frames_sfx,
		  append, effect = ...

	--Clean up variables
	emote_modifier = self:tointeger(emote_modifier)
	char_id = self:tointeger(char_id)
	sfx_delay = self:tointeger(sfx_delay)
	shout_modifier = self:tointeger(shout_modifier)
	evidence = self:tointeger(evidence)
	text_color = self:tointeger(text_color)
	pair = self:tointeger(pair)
	hscroll = self:tointeger(hscroll)
	flip = self:tointeger(flip) == 1
	realization = self:tointeger(realization) == 1
	shake = self:tointeger(shake) == 1
	no_interrupt = self:tointeger(no_interrupt) == 1
	sfx_looping = self:tointeger(sfx_looping) == 1
	append = self:tointeger(append) == 1
	if message then message = self:unescape(message) end

	local fg
	local bg
	local zoom = emote_modifier == 5 or emote_modifier == 6
	local side_name = side

	if desk == "1" then
		desk = true
	else
		desk = false
	end
	if zoom then
		desk = false

		bg = "defense_speedlines"
		if side == "wit" or side == "pro" or side == "hlp" then
			bg = "prosecution_speedlines"
		end
	end
	if desk then
		fg = "desk"
	else
		fg = false
	end

	if side == "wit" then side = SIDE_WIT
	elseif side == "def" then side = SIDE_DEF
	elseif side == "pro" then side = SIDE_PRO
	elseif side == "jud" then side = SIDE_JUD
	elseif side == "hld" then side = SIDE_HLD
	elseif side == "hlp" then side = SIDE_HLP
	elseif side == "sea" then side = SIDE_SEA
	else side = SIDE_JUR
	end

	--Pre-emotes
	if not no_interrupt and emote_modifier == 0 or emote_modifier > 4
	or pre_emote == "-" or zoom then
		pre_emote = nil
		sfx_name = 1
		sfx_delay = 0
	end

	if pair then
		pair_id = self:getCharacterName(client,pair)
		pair = self:getCharacterName(client,pair)
	end

	char_id = self:getCharacterName(client,char_id) or char_id

	if showname == "" or showname == "0" then
		showname = nil
	end

	process:send(client,"IC",{
		dialogue=message or "nil",
		character=character or "nil",
		emote=emote or "nil",

		pre_emote=pre_emote,
		name=showname,

		interjection=shout_modifier,

		side=side,
		side_name = side_name,
		item=evidence,

		bg=bg,
		fg=fg,

		flip=flip,

		pair=pair,
		hscroll=hscroll,
		vscroll=vscroll,

		no_interrupt=no_interrupt,

		sfx_name=sfx_name,
		sfx_delay=sfx_delay,
		sfx_looping=sfx_looping,

		realization=realization,
		shake=shake,

		text_color=text_color,
		append=append,

		char_id=char_id,
		pair_id=pair_id,

		effect=effect,
	})
end
--Music Choice
AO2.input["MC"] = function(self,client,process,call, track, id, cc_showname, effects, looping, channel)
	if not track or not self:tointeger(id) then return end
	if track == "" then return end
	process:send(client,"MUSIC", {
		track = self:unescape(tostring(track)),
		character = self:getCharacterName(client, self:tointeger(id)),
		name = cc_showname and cc_showname ~= "0" and self:unescape(tostring(cc_showname)),
		looping = self:tointeger(looping),
		channel = self:tointeger(channel),
		effects = self:tointeger(effects),
	})
end
--HP
AO2.input["HP"] = function(self,client,process,call, side, amount)
	if not self:tointeger(side) then return end
	if not self.state[client].hp then return end
	local prevhp = self.state[client].hp[self:tointeger(side)]
	local currhp = self:tointeger(amount)
	if not prevhp or not currhp then return end

	process:send(client,"EVENT", {
		event="hp",
		side=tonumber(side),
		amount=tonumber(amount),
		change=currhp-prevhp,
	})
end
--Woosh effect
AO2.input["RT"] = function(self,client,process,call, event, ...)
	if not event then return end

	--Make it more readable. We will translate back anyway. ;)
	local name
	if event == "testimony1" then
		name = "witness_testimony"
		if ... then
			name = "disable_testimony"
		end
	end
	if event == "testimony2" then
		name = "cross_examination"
	end
	if event == "judgeruling" then
		if ... == "0" then
			name = "verdict_notguilty"
		else
			name = "verdict_guilty"
		end
	end
	if name then
		process:send(client,"EVENT", {
			event=self:unescape(name),
		})
	end
end
--AO1 message: Close
AO2.input["DC"] = function(self,client,process,call)
	process:send(client,"CLOSE")
end
--Evidence Add
AO2.input["PE"] = function(self,client,process,call, name,desc,image)
	process:send(client,"ITEM_ADD",{
		name=tostring(name),
		description=tostring(desc),
		image=tostring(image),
	})
end
--Evidence Remove
AO2.input["DE"] = function(self,client,process,call, id)
	process:send(client,"ITEM_REMOVE",{
		id=self:tointeger(id),
	})
end
--Evidence Edit
AO2.input["EE"] = function(self,client,process,call, id,name,desc,image)
	process:send(client,"ITEM_EDIT",{
		id=self:tointeger(id),
		name=tostring(name),
		description=tostring(desc),
		image=tostring(image),
	})
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
AO2.input["48F9"] = AO2.input["HP"]
AO2.input["5289"] = AO2.input["RT"]
AO2.input["4422"] = AO2.input["DC"]
AO2.input["507C"] = AO2.input["PE"]
AO2.input["4576"] = AO2.input["EE"]
AO2.input["4424"] = AO2.input["DE"]

--Messages sent from server to clients
function AO2:send(client,process, call,data)
	if not self.state[client] then return end
	if not AO2.output[call] then return end

	AO2.output[call](self,client,process,data)
end

AO2.output["INFO_SEND"] = function(self,client,process,data)
	client:bufferraw("decryptor#34#%")
	client:bufferraw("PN#"..(data.players).."#"..(data.maxplayers).."#%")
	client:bufferraw("ID#0#"..(data.software).."#"..(data.version).."#%")
	client:bufferraw("FL#yellowtext#customobjections#flipping#fastloading#deskmod#evidence#modcall_reason#cccc_ic_support#arup#casing_alerts#looping_sfx#additive#effects#y_offset#expanded_desk_mods#auth_packet#%")
	if config.assets and config.assets ~= "" then
		client:bufferraw("ASS#"..tostring(config.assets).."#%")
	end
end

AO2.output["JOIN_ALLOW"] = function(self,client,process,data)
	local c = #process:getCharacters(client)
	local m = #process:getMusic(client)
	client:bufferraw("SI#"..c.."#1#"..m.."#%") --AO2 does not rely on these numbers.

	if client.software == "AO" then
		client.received = client.received .. "askchar2#%"
	end
end
AO2.output["JOIN_DENY"] = function(self,client,process,data)
end

AO2.output["CHAR_PICK"] = function(self,client,process,data)
	if type(data.character) == "string" then
		local char_id = self:getCharacterId(client, data.character)

		if char_id == -1 then
			--Character not found in the client list!
			--AO2 does not (yet) support picking by string unfortunately.

			--Sending a new character list results in no change or a seg fault, may have to revisit.
			local char_list = self.state[client].char_list
			--client:sendraw("CI#0#" .. data.character .. "&&0&&&0#%")

			char_id = 0
		end

		client:bufferraw("PV#0#CID#"..char_id.."#%")
	else
		--Set client as spectator.
		client:bufferraw("PV#0#CID#-1#%")
	end
end

AO2.output["OOC"] = function(self,client,process,data)
	local msg = "CT#"
	msg=msg..self:escape(data.name or "").."#"
	msg=msg..self:escape(data.message or "").."#"
	if data.server then
		msg=msg.."1#"
	end
	client:bufferraw(msg.."%")
end
AO2.output["IC"] = function(self,client,process,data)
	local ms = "MS#"
	local t  = {}
	if client.software == "AO" or client.software == "webAO" then
		t[#t+1] = "chat"
	else
		t[#t+1] = data.fg and 1 or 0
	end
	t[#t+1] = self:escape(data.pre_emote or "none") --"-" completely disables sound.
	t[#t+1] = self:escape(data.character or " ")
	t[#t+1] = self:escape(data.emote or "normal")
	--Dialogue
	local dialogue = data.dialogue or ""
	t[#t+1] = self:escape(dialogue)
	--Position
	local side = "wit"
	if data.side == SIDE_DEF then side = "def"
	elseif data.side == SIDE_PRO then side = "pro"
	elseif data.side == SIDE_JUD then side = "jud"
	elseif data.side == SIDE_HLD then side = "hld"
	elseif data.side == SIDE_HLP then side = "hlp"
	elseif data.side == SIDE_JUR then side = "jur"
	elseif data.side == SIDE_SEA then side = "sea"
	end
	if data.bg == "defense_speedlines" then side = "def" end
	if data.bg == "prosecution_speedlines" then side = "pro" end
	t[#t+1] = side
	--Sound name
	t[#t+1] = data.sfx_name or 1
	--Emote modification
	local emote_modifier = 0
	if not data.no_interrupt then
		if data.pre_emote then
			emote_modifier = 1
		end
		if data.bg then
			emote_modifier = 5
		end
		if data.interjection and data.interjection ~= 0 then
			emote_modifier = emote_modifier + 1
		end
		if data.sfx_name and data.bg then
			emote_modifier = 6
		end
	end
	t[#t+1] = emote_modifier
	local char_id = data.char_id and self:getCharacterId(client, data.char_id) or self:getCharacterId(client, data.character) or -1
	if char_id == -1 then
		char_id = 0
	end
	t[#t+1] = char_id
	--Sound delay
	t[#t+1] = data.sfx_delay or 0
	--Shout modifier
	t[#t+1] = data.interjection or 0
	--Evidence
	t[#t+1] = data.item or 0
	--Flip
	if client.software == "AO" then
		t[#t+1] = char_id
	else
		t[#t+1] = data.flip and 1 or 0
	end
	t[#t+1] = data.realization and 1 or 0
	local text_color = self:tointeger(data.text_color) or 0
	if client.software == "AO" and text_color == 5 then text_color = 3 end
	t[#t+1] = text_color
	--Shownames.
	t[#t+1] = data.name or ""
	--Character pairing.
	local pair_id = data.pair_id and self:getCharacterId(client, data.pair_id) or self:getCharacterId(client, data.pair) or -1
	if pair_id ~= -1 and data.pair and data.pair_emote then
		t[#t+1] = pair_id or -1
		t[#t+1] = data.pair or ""
		t[#t+1] = data.pair_emote or "-"
		t[#t+1] = data.hscroll or 0
		t[#t+1] = data.pair_hscroll or 0
		t[#t+1] = data.pair_flip and 1 or 0
		t[#t+1] = data.no_interrupt and 1 or 0
	else
		t[#t+1] = -1
		t[#t+1] = ""
		t[#t+1] = ""
		t[#t+1] = 0
		t[#t+1] = 0
		t[#t+1] = 0
		t[#t+1] = 1
	end
	t[#t+1] = data.sfx_looping and 1 or 0
	t[#t+1] = data.shake and 1 or 0
	t[#t+1] = ""
	t[#t+1] = ""
	t[#t+1] = ""
	t[#t+1] = data.append and 1 or 0
	t[#t+1] = data.effect or ""

	client:bufferraw(ms..table.concat(t,"#").."#%")
end

AO2.output["MUSIC"] = function(self,client,process,data)
	--WebAO looping fix.
	local mc = "MC#"
	mc=mc .. self:escape(tostring(data.track)).."#"
	mc=mc .. self:getCharacterId(client, data.character).."#"
	mc=mc .. self:escape(tostring(data.name or "")).."#"
	if data.looping or data.channel or data.effects then
		mc=mc .. (data.looping and 1 or 0).."#"
		mc=mc .. (self:tointeger(data.channel) or 0).."#"
		mc=mc .. (self:tointeger(data.effects) or 0).."#"
	end
	client:bufferraw(mc.."%")
end

AO2.output["BG"] = function(self,client,process,data)
	client:bufferraw("BN#"..self:escape(data.bg).."#%")
end

AO2.output["EVENT"] = function(self,client,process,data)
	if data.event == "witness_testimony" then
		client:bufferraw("RT#testimony1#%")
	elseif data.event == "cross_examination" then
		client:bufferraw("RT#testimony2#%")
	elseif data.event == "verdict_notguilty" then
		client:bufferraw("RT#judgeruling#0#%")
	elseif data.event == "verdict_guilty" then
		client:bufferraw("RT#judgeruling#1#%")
	elseif data.event == "hp" then
		if self.state[client].hp then
			self.state[client].hp[data.side] = data.amount
		end
		client:bufferraw("HP#"..(data.side or 0).."#"..(data.amount or 0).."#%")
	elseif data.event == "arup_count" then
		local list = ""
		client:bufferraw("ARUP#0#"..table.concat(data,"#").."#%")
	elseif data.event == "arup_status" then
		local list = ""
		client:bufferraw("ARUP#1#"..table.concat(data,"#").."#%")
	elseif data.event == "arup_cm" then
		local list = ""
		client:bufferraw("ARUP#2#"..table.concat(data,"#").."#%")
	elseif data.event == "arup_lock" then
		local list = ""
		client:bufferraw("ARUP#3#"..table.concat(data,"#").."#%")
	end
end

AO2.output["SIDE"] = function(self,client,process,data)
	local side = "wit"
	if data.side == SIDE_DEF then side = "def"
	elseif data.side == SIDE_PRO then side = "pro"
	elseif data.side == SIDE_JUD then side = "jud"
	elseif data.side == SIDE_HLD then side = "hld"
	elseif data.side == SIDE_HLP then side = "hlp"
	elseif data.side == SIDE_JUR then side = "jur"
	elseif data.side == SIDE_SEA then side = "sea"
	end
	client:bufferraw("SP#"..side.."#%")
end
AO2.output["SIDE_LIST"] = function(self,client,process,data)
	local list = table.concat(data,"*")
	client:bufferraw("SD#"..list.."#%")
end

AO2.output["ITEM_LIST"] = function(self,client,process,data)
	local list = ""
	for i,v in ipairs(data) do
		list=list..v.name.."&"
		list=list..v.description.."&"
		list=list..v.image.."#"
	end
	client:bufferraw("LE#"..list.."%")
end

AO2.output["LOAD_CHARS"] = function(self,client,process,data)
	self:sendAssetList(client,"SC",self.state[client].char_list)
end
AO2.output["LOAD_MUSIC"] = function(self,client,process,data)
	self:sendAssetList(client,"REFMUSIC",self.state[client].music_list)
end

AO2.output["KICK"] = function(self,client,process,data)
	client:bufferraw("KK#"..tostring(data.reason).."#%")
end
AO2.output["BAN"] = function(self,client,process,data)
	client:bufferraw("KB#"..tostring(data.reason).."#%")
end
AO2.output["NOTICE"] = function(self,client,process,data)
	client:bufferraw("BB#"..tostring(data.message).."#%")
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
	return str:gsub("%#","<num>")
	:gsub("%$","<dollar>")
	:gsub("%%","<percent>")
	:gsub("%&","<and>")
end

function AO2:unescape(str)
	return str:gsub("%<num%>","#")
	:gsub("%<dollar%>","$")
	:gsub("%<percent%>","%%")
	:gsub("%<and%>","&")
end

function AO2:hexToString(hex)
	local str = ""
	for i=1,math.ceil(#hex/2)*2,2 do
		str = str..string.char( tonumber(hex:sub(i,i+1),16) or 0 )
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

function AO2:getCharacterId(client,name)
	local char_id = 0
	if self.state[client] then
		local characters = self.state[client].char_list
		if characters then
			for i,v in ipairs(characters) do
					if v == name then
					char_id = i
					break
				end
			end
		end
	end
	return char_id-1
end

function AO2:getCharacterName(client,id)
	local char_name = "N/A"
	if self.state[client] then
		local characters = self.state[client].char_list
		if characters then
			for i,v in ipairs(characters) do
				if i == id+1 then
					char_name = v
					break
				end
			end
		end
	end
	return char_name
end

--Character list shenanigans.
function AO2:sendAssetList(client,command,t,page)
	local list = ""
	if not page then
		for i,v in ipairs(t) do
			list = list .. self:escape(v) .. "#"
		end
	else
		for i3=1,(10) do
			local id = (page-1)*10+i3
			if t[id] then
				list = list .. id-1 .. "#" .. self:escape(t[id]) .. (command=="CI"and"&&0&&&0"or"") .."#"
			else
				break
			end
		end
	end
	client:bufferraw(command.."#"..list.."%")
end

function AO2:makeNameList(t, key)
	local list = {}
	for k,v in pairs(t) do
		local name
		local value = v[key or "name"]
		if type(value) == "string" then
			name = value
		elseif type(value) == "function" then
			name = value(v)
		end
		table.insert(list,name)
	end
	return list
end

function AO2:finishLoad(client,process)
	if self.state[client].finished then return true end

	self.state[client].finished = true

	client:bufferraw("CharsCheck#0#%")
	client:bufferraw("DONE#%")
	process:send(client,"DONE")
end

return AO2
