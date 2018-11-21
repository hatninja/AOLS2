--Cache messages to be sent.
local characters = dofile(path.."settings/characters.lua")
local SC = ""
local CharsCheck = ""
for i=1,#characters do
	SC = SC..characters[i].."#"
	--CharsCheck = CharsCheck.."0#"
end

local music = dofile(path.."settings/music.lua")
local musiccount = 0
local SM = ""
SM = SM .. music[1].."#"
SM = SM .. music[2].."#"
for k in pairs(music.games) do SM = SM ..k.."#"; musiccount = musiccount+1 end
SM = SM .. music[3].."#"
for k,t in pairs(music.themes) do SM = SM ..t.."#"; musiccount = musiccount+1 end
SM = SM .. music[4].."#"
for k,c in pairs(music.charthemes) do SM = SM ..c.."#"; musiccount = musiccount+1  end
SM = SM .. music[5].."#"
for k,m in pairs(music.misc) do SM = SM ..m.."#"; musiccount = musiccount+1  end
musiccount = musiccount+5

local SI = #characters.."#0#"..musiccount.."#"

local backgrounds = dofile(path.."settings/backgrounds.lua")

--Localization or something
local text = dofile(path.."settings/text.lua")

--Feature locks
dofile(path.."settings/features.lua")

--Filters for spam or language.
local filters = dofile(path.."settings/filters.lua")

local analyticsavetime = os.time()
--local analyticupdatetime = os.time()+60

local rooms = dofile(path.."settings/rooms.lua")
local staticrooms = #rooms

local bans = loadlist(path.."bans.txt")

--Initialize rooms
function initializeroom(i)
	local v = rooms[i]
	v.id = i
	v.count = 0
	v.clients = {}
	if v.kind == "court" then
		v.hp={10,10}
		v.status="IDLE"
		v.evidence = {}
	end
	if v.kind ~= "echo" then
		v.mbuffer = {} --Message buffer.
	end
	if v.kind == "portal" then
		v.socket = socket.tcp()
		v.socket:settimeout(0)
		v.socket:connect(v.ip,v.port)
	end
	if feature_replay then
		v.replay = {}
	end
end
for i=1,#rooms do initializeroom(i) end

local clientcount = 0
local viewers = {}
local clients = {}
function doaccept(socket)
	local ip,port = socket:getpeername()
	viewers[socket] = {
		viewtime = os.time(), --If they continue viewing for a minute, it will automatically disconnect them to free up room.
		spamcounter = 0,
		count=0,
		buffer="",
		socket=socket,
		ip=ip,
		port=port,
	}
	--print(tostring(ip)..":"..tostring(port).." is viewing.")
	
	if clientcount < maxplayers then
		local isbanned = table.find(bans,ip)
		if not isbanned then
			buffersend(socket,"decryptor#34#%")
			buffersend(socket,"HI#AOls#beta#%")
			buffersend(socket,"ID#"..firstempty(clients).."#AOls#beta#%")
			buffersend(socket,"PN#"..clientcount.."#"..maxplayers.."#%")
		else
			doclosed(socket)
			print("Banned client tried to connect! IP: "..tostring(ip))
		end
	else
		doclosed(socket)
	end
end

function doclosed(socket)
	local client = clients[socket]
	if client then
		local id = client.id
		if client.room then
			clientcount=clientcount-1
		end
		leaveroom(client,"disconnected.")
		
		clients[id] = nil
		clients[socket] = nil
		
		print("Client["..id.."] disconnected.")
	end
	local viewer = viewers[socket]
	if viewer then
		viewers[socket] = nil
	end
	if socket then
		socket:close()
	end
end

function dosubcommand(socket,sc)
	local client = viewers[socket] or clients[socket]
	
	local subcommand = sc
	if subcommand:sub(1,1) == "#" then subcommand = subcommand:sub(2,-1) end
	
	local args = string.split(subcommand,"#")
	
	if #args[1] == 4 then args[1] = decryptStr(hexToString(args[1]), 5) end
	
	if not client then
		if args[2] ~= "ms2" then --Ignore ms2 prober's second message.
			print("Received message from unknown client!",table.concat(args,"#"),socket:getpeername())
		end
		return
	end
	
	--print(subcommand)
	--print(table.concat(args,"#"))
	
	--Handshake
	if args[1] == "HI" then
		client.hardwareid = args[2]
		buffersend(socket,"FL#yellowtext#customobjections#flipping#fastloading#deskmod#noencryption#%")
	end
	if args[1] == "ID" then client.software = args[2] end
	
	--Start join
	if args[1] == "askchaa" and not client.id then --Id is added when the client sends this message, so this will prevent accidental extra joins.
		local id = firstempty(clients)
		
		local ip,port = client.socket:getpeername()
		print(tostring(ip)..":"..tostring(port).." is now joining with id: "..id.."\n"..tostring(client.software).." "..tostring(client.hardwareid))
		
		buffersend(socket,"SI#"..SI.."%")
		
		clients[id] = client
		clients[client.socket] = client
		viewers[socket] = nil
		
		client.id = id
	end
	--Loading 2.0
	if args[1] == "RC" then buffersend(socket,"SC#"..SC.."%")
	elseif args[1] == "RM" then buffersend(socket,"SM#"..SM.."%")
	end
	--End of loading.
	if args[1] == "RD" then
		buffersend(socket,"CharsCheck#"..CharsCheck.."%")
		buffersend(socket,"DONE#%")
		
		if text.motd then
			botmessage(socket,text.motd)
		end

		CTcommand(client,"","/area")
		
		joinroom(client,1,"connected to the server.")
		
		clientcount=clientcount+1
	end

	
	--Keep clients updated.
	if args[1] == "CH" then buffersend(socket,"CHECK#%") end
	
	--Character Picking
	if args[1] == "CC" then CC(client,tonumber(args[3])) end
	
	--Mod call
	if args[1] == "ZZ" then
		print("Client["..client.id.."] called for mods in room "..(client.room.id))
		for i,v in ipairs(clients) do
			if v.mod then
				buffersend(v.socket,"CT#"..escapeChat(serverooc).."#["..(client.room.id).."][("..(client.id)..")"..getcharname(client.charid).."] called for a mod.#%")
			end
		end
	end
	
	--Room Commands: 
	
	--Messaging
	if args[1] == "CT" then CT(client,client.nick or (args[2] ~= "" and args[2]) or tostring("client"..client.id), args[3]) end
	
	--The big one ^^;
	if args[1] == "MS" then
		local room = client.room
		if not client.charid then return end --You can't use MS as spectator!
		if room.roommute and not client.mod then return end
		if client.muted then return end
			
		local desk = client.desk or args[2]
		if desk ~= "0" and desk ~= "1" and desk ~= "chat" then return end
		
		local pre_emote = args[3]
		local character = feature_iniswap and args[4] or getcharname(client.charid)

		local emote = args[5]
		
		local message = args[6]
		
		local side = args[7]
		if side ~= "def" and side ~= "pro" and side ~= "jud" and side ~= "wit" and side ~= "hld" and side ~= "hlp" then return end
		if not client.pos then setnewpos(client,side) end --Reminder: Position is reset when you join a new room.
		side = client.pos
		--Check for room pos!
		
		local sfx_name = args[8]
		local emote_modifier = tonumber(args[9])
		if not emote_modifier or emote_modifier < 0 or emote_modifier > 6 or emote_modifier ~= math.floor(emote_modifier) then return end
		
		local char_id = client.charid --Ignore args[10]
		
		local sfx_delay = tonumber(args[11]) or 0
		if not sfx_delay or sfx_delay ~= math.floor(sfx_delay) then return end
		
		local shout_modifier = tonumber(args[12]) or 0
		if not shout_modifier or shout_modifier ~= math.floor(shout_modifier) then return end
		
		local evidence = tonumber(args[13]) or 0
		if not evidence or evidence ~= math.floor(evidence) then return end
		
		local flip = args[14] --Replace with char_id for 1.x versions
		if flip ~= "0" and flip ~= "1" then return end
		
		local realization = args[15]
		if realization ~= "0" and realization ~= "1" then return end
		
		local text_color = tonumber(args[16])
		if not text_color or text_color < 0 or text_color > 6 then return end
		if text_color == 0 and feature_autocolor then --Ignore if the user wants a different color.
			if message:find("^%([^%(].-[^%)]%)$") then text_color = 4 end --(Thinking brackets are most likely blue)!
			if message:find("^%*.-%*$") then text_color = 3 end --Action text *Is orange*
		end
		if message:sub(1,9) == "<percent>" then
			local tc
			local i = 10
			if string.lower(message:sub(i,i)) == "w" then tc = 0
			elseif string.lower(message:sub(i,i)) == "g" then tc = 1
			elseif string.lower(message:sub(i,i)) == "r" then tc = 2
			elseif string.lower(message:sub(i,i)) == "o" then tc = 3
			elseif string.lower(message:sub(i,i)) == "b" then tc = 4
			elseif string.lower(message:sub(i,i)) == "y" then tc = 5
			elseif string.lower(message:sub(i,i)) == "s" then tc = 6
			end
			if tc then
				message = message:sub(11,-1)
				text_color = tc
			end
		end
		if text_color == 6 and not feature_rainbowtext then text_color = 0 end --We don't need that eyebleeder :P
		
		if #message > icmaxlength then message = message:sub(1,icmaxlength) end
		
		--if spamcheck(client,message) then
		--	message = "*****"
		--end
		
		local msg = "MS#"..table.concat({desk, pre_emote, character, emote, message, side, sfx_name, emote_modifier, char_id, sfx_delay, shout_modifier, evidence, flip, realization, text_color},"#").."#%"
		
		local sent = false
		if room and room.kind ~= "echo" then
			if msg ~= client.lm then
				client.lm = msg
				if room.lmt then
					if #room.mbuffer < 5 then --If somebody gets to this point, it's spamming.
						room.mbuffer[#room.mbuffer+1] = msg
						sent = true
					end
				else
					broadcastroom(room,msg)
					room.lmt = msgbuffertime
					sent = true
				end
			end
		else
			buffersend(socket,msg)
		end
		
		if sent then
			print("Client["..(client.id).."]["..getcharname(client.charid).."]["..tostring(client.room and client.room.name).."]: "..message)
			
			if feature_replay then
				table.insert(room.replay,{os.time(), "MS", desk, pre_emote, character, emote, message, side, sfx_name, emote_modifier, char_id, sfx_delay, shout_modifier, 0, flip, realization, text_color})
			end
		end
	end
	
	--Music
	if args[1] == "MC" then
		local track = args[2]
		
		--Game selector.
		if not client.musictheme then client.musictheme = "AA" end
		for k,v in pairs(music.games) do
			if args[2] == k then
				track = nil
				
				client.musictheme = k
				botmessage(socket,string.format(text.musictheme,k))
				break
			end
		end
		
		--Game theme.
		for k,v in pairs(music.themes) do
			if args[2] == v then
				track = music.games[client.musictheme][v]
				break
			end
		end
		
		if args[2]:sub(1,1):find("[^0-9a-zA-Z]") then
			track = music[1]
		end
		
		--Otherwise, just a misc music track.
		if track and client.charid then
			if client.room and client.room.kind ~= "echo" and not client.muted then
				if track ~= client.room.music then
					client.room.music = track
					broadcastroom(client.room,"MC#"..track.."#"..client.charid.."#%")
					client.room.lastplay = os.time()
					
					if feature_replay then
						table.insert(client.room.replay,{os.time(), "MC", track, client.charid})
					end

					analytics:track("music",track)
				end
			else
				buffersend(socket,"MC#"..track.."#"..client.charid.."#%")
			end
		end
	end
	
	--Courtroom commands!
	--WT woosh!
	if args[1] == "RT" then
		if args[2] == "testimony1" or args[2] == "testimony2" then
			if client.room.kind == "court" and not client.muted then
				broadcastroom(client.room,"RT#"..args[2].."#%")
				
				if feature_replay then
					table.insert(client.room.replay,{os.time(), "RT", args[2]})
				end
			elseif client.room.kind == "echo" and not client.muted then
				buffersend(client.socket,"RT#"..args[2].."#%")
			end
			if client.lastwoosh then
				if os.clock() <= client.lastwoosh+1/11 then
					client.spamcounter = client.spamcounter + 1
				end
			end
			client.lastwoosh = os.clock()
		end
	end
	--HP!
	if args[1] == "HP" then
		local hpbar = tonumber(args[2])
		local amount = tonumber(args[3])
		if hpbar and amount then
			if amount >= 0 and amount <= 10 then
				if client.room.kind == "court" and not client.muted then
					client.room.hp[hpbar]=amount
					broadcastroom(client.room,"HP#"..hpbar.."#"..amount.."#%")
					
					if feature_replay then
						table.insert(client.room.replay,{os.time(), "HP", hpbar, amount})
					end
				elseif client.room.kind == "echo" then
					buffersend(client.socket,"HP#"..hpbar.."#"..amount.."#%")
				end
			end
		end
	end
	
	--Evidence
	if client.room and client.room.kind == "court" and not client.muted then
		if args[1] == "PE" and #client.room.evidence < maxevidence then --Add
			table.insert(client.room.evidence,{"name","description",args[4]})
			listevidence(client,true)
		elseif args[1] == "DE" then --Delete
			if client.room.evidence[1] then
				table.remove(client.room.evidence,(tonumber(args[2]) or 0)+1)
			end
			listevidence(client,true)
		elseif args[1] == "EE" then --Edit
			client.room.evidence[(tonumber(args[2]) or 0)+1] = {args[3],args[4],args[5]}
			listevidence(client,true)
		end
	end
end

function listevidence(client,update)
	if client.room and client.room.evidence then
		if not client.room.evidencestring or update then
			local evidence = "LE#"
			for i,v in ipairs(client.room.evidence) do
				evidence = evidence .. v[1] .. "&" .. v[2] .. "&" .. v[3] .. "#"
			end
			evidence = evidence .. "%"
			client.room.evidencestring = evidence
			
			broadcastroom(client.room,client.room.evidencestring)
		else
			buffersend(client.socket,client.room.evidencestring)
		end
	else
		buffersend(client.socket,"LE#%")
	end
end

function doupdate(dt)
	local currenttime = os.time()
	local subtract = 0
	for i=#rooms,1,-1 do local v = rooms[i]
		v.id = v.id - subtract
		if v.kind ~= "echo" then
			if v.lmt then
				v.lmt = v.lmt - dt
				if v.lmt <= 0 then
					local msg = v.mbuffer[#v.mbuffer]
					if msg then
						broadcastroom(v,v.mbuffer[#v.mbuffer])
						v.mbuffer[#v.mbuffer] = nil
						v.lmt = msgbuffertime
					else
						v.lmt = nil
					end
				end
			end
			if v.lastplay then
				local track = v.music
				if music.lengths[track] then
					local length = music.lengths[track]
					if currenttime > v.lastplay+length then
						broadcastroom(v,"MC#"..track.."#-1#%")
						v.lastplay = currenttime
					end
				end
			end
		end
		if v.kind == "court" and i > staticrooms then
			if v.count == 0 then
				subtract = subtract + 1
				table.remove(rooms,i)
			end
		end
	end
	for i,v in pairs(clients) do
		if tonumber(i) then
			if v.spamcounter > 10 then
				doclosed(v.socket)
				print("Client["..i.."] was automatically kicked due to spamming!")
				break
			end
			v.spamcounter = math.max(v.spamcounter-(1/10),0)
		end
		if v.replay then			
			if v.room.replay[v.replay] and os.time()-v.replayoffset > v.room.replay[v.replay][1] then
				local data = {unpack(v.room.replay[v.replay])}
				table.remove(data,1)
				buffersend(v.socket, table.concat(data,"#").."#%")
				v.replay = v.replay+1
			end
			if v.replay > v.replayend then
				v.replay = nil
				v.replayend = nil
				v.replayoffset = nil
			end
		end
	end
	for k,v in pairs(viewers) do
		if os.time() > v.viewtime+60 then
			if v.ip ~= mservip then
				doclosed(v.socket)
				--print("Client["..i.."] timed out viewing the server!")
			end
		end
	end
	if os.time() > analyticsavetime then
		analyticsavetime = os.time()+(60*60*12)
		analytics:save("chars")
		analytics:save("music")
	end
end

function CT(client, name,message)
	local socket = client.socket
	if not name:find("[a-zA-Z]") then botmessage(socket,text.OOCnoletters);return end
	
	if #name > oocmaxnamelength then botmessage(socket,string.format(text.OOClongname,oocmaxnamelength));return end
	if #message > oocmaxlength then
		botmessage(socket,string.format(text.OOClongmsg,oocmaxlength))
		message:sub(1,oocmaxlength)
	end
	
	if message:sub(1,1) == "/" then
		if not CTcommand(client, name,message) then
			botmessage(socket,text.invalidcommand)
		end
		return
	end
	
	if client.room then
		broadcastroom(client.room,"CT#["..client.id.."] "..name.."#"..message.."#%")
	end
end

--TODO: Make a hash-table function list, much better than if-thens.
function CTcommand(client, name,message) --Return true to say that the command was valid.
	local socket = client.socket
	local args = string.split(message," ")
	
	if name ~= "" then print("Client["..(client.id).."]["..name.."]["..tostring(client.room and client.room.name).."]: "..message) end

	if feature_replay and args[1] == "/replay" then
		if tonumber(args[2]) then
			botmessage(client.socket,"Playing replay from -"..tostring(args[2]).." seconds ago to now.")
			for i=#client.room.replay,1,-1 do
				if os.time()-tonumber(args[2]) < client.room.replay[i][1] then
					client.replay = i
					break
				end
			end
			if client.replay then
				client.replayend = #client.room.replay
				client.replayoffset = tonumber(args[2])
			end
		end
		return true
	end

	--Regular commands.
	if args[1] == "/motd" then
		if text.motd then
			botmessage(client.socket,text.motd)
			return true
		end
	end
	if args[1] == "/help" then
		if text.help then
			botmessage(client.socket,text.help)
			return true
		end
	end
	if args[1] == "/rules" then
		if text.rules then
			botmessage(client.socket,text.rules)
			return true
		end
	end
	if args[1] == "/files" then
		if text.files then
			botmessage(client.socket,text.files)
			return true
		end
	end
	
	if args[1] == "/area" or args[1] == "/areas" then
		if client.trapped then return false end
		if args[2] then
			if tonumber(args[2]) then
				local room = rooms[tonumber(args[2])]
				if room then
					if not room.lock or room.lock == args[3] then
						if not room.modlock or room.modlock and client.mod then
							joinroom(client,tonumber(args[2]))
							botmessage(client.socket,text.joiningheader.."\n"..string.format(text.changedroom,client.room.name))
							if client.room.desc then
								botmessage(client.socket,client.room.desc)
							end
						else
							botmessage(client.socket,"Warning: This room is locked to moderators only!")
						end
					else
						botmessage(client.socket,"Warning: This room is locked. Please add the correct passcode to your command.")
					end
				else
					botmessage(client.socket,"Warning: A room with that id doesn't exist!")
				end
			elseif args[2] == "+" and feature_dynamicrooms then
				local name = message:sub(9,-1)
				if name == "" then name = nil end
				
				local newroomid = #rooms+1
				rooms[newroomid] = {
					name = name or "New Courtroom",
					desc = nil,
					bg=backgrounds[math.random(1,#backgrounds)],
					music="No Music",
					kind="court",
				}
				initializeroom(newroomid)
				joinroom(client,newroomid)
			else --Find by name?
				--
				local search = string.lower(message:sub(7,-1))
				if search ~= "" then
					local found = false
					for i=1,#rooms do local v = rooms[i]
						if string.lower(v.name):find(search) and not v.lock and (not v.modlock or v.modlock and client.mod) then
							joinroom(client,i)
							botmessage(client.socket,text.joiningheader.."\n"..string.format(text.changedroom,client.room.name))
							if client.room.desc then
								botmessage(client.socket,client.room.desc)
							end
							found = true
							break
						end
					end
					if not found then
						botmessage(client.socket,string.format("Warning: Could not find room with search '%s'",search))
					end
				else
					botmessage(client.socket,text.notanumber)
				end
			end
		else
			local msg = text.roomlistheader.."\n"
			for i=1, #rooms do local v = rooms[i]
				if i <= staticrooms then
					msg = msg .. i ..": "..v.name
				else
					msg = msg ..i..": \""..v.name.."\""
				end
				msg = msg .." "
				if v.lock then
					msg = msg .."[Pass]"
				end
				if v.modlock then
					msg = msg .."[Mods]"
				end
				if v.kind == "court" then
					msg = msg .."["..v.status.."]"
				end
				msg = msg .." ("..v.count..")"
				msg = msg.."\n"
			end
			if feature_dynamicrooms then
				msg = msg.."+: (Make Courtroom)"
			end
			
			botmessage(client.socket,msg)
		end
		return true
	end
	if args[1] == "/getarea" or args[1] == "/whois" then
		if tonumber(args[2]) then --Get person details
			local target = clients[tonumber(args[2])]
			if target then
				if target.room then
					if target.room == client.room then
						botmessage(client.socket,string.format(text.whoisuinroom,target.id,getcharname(target.charid),target.pos or "N/A"))
					else
						botmessage(client.socket,string.format(text.whoisufindroom,target.id,target.room.id,target.room.name))
					end
				else
					botmessage(client.socket,string.format(text.whoisunoroom,args[2]))
				end
			else
				botmessage(client.socket,text.whoisunotfound)
			end
		else --Get room list.
			local msg = client.room.count.." people in this room.".."\n"..text.whoisheader.."\n"

			for cli in pairs(client.room.clients) do
				msg = msg .. string.format(text.whoisformat, cli.id, getcharname(cli.charid), cli.pos or "N/A")
			end
			botmessage(client.socket,msg)
		end
		return true
	end
	if args[1] == "/getareas" then
		local msg = ""
		for i=1,#rooms do local v = rooms[i]
			if v.count > 0 then
				msg = msg .. "=="..v.name.."==\n"
				for cli in pairs(v.clients) do
					msg = msg .. string.format(text.whoisformat, cli.id, getcharname(cli.charid), cli.pos or "N/A")
				end
			end
		end
		botmessage(client.socket,msg)
		return true
	end
	if args[1] == "/players" then
		botmessage(client.socket,clientcount.." players online.")
		return true
	end

	if not client.muted and args[1] == "/g" then
		if args[2] then
			for k,v in pairs(clients) do
				if not tonumber(k) then
					buffersend(v.socket,"CT#"..escapeChat(serverooc)..getroomname(client.room).."(["..(client.id).."] "..name..")#"..escapeChat(message:sub(4,-1)).."#%" )
				end
			end
		else
			botmessage(client.socket,text.ghelp)
		end
		return true
	end
	if feature_need and not client.muted and args[1] == "/need" then
		if args[2] then
			for i=1,#clients do local v = clients[i]
				if v then
					buffersend(v.socket,"CT#"..escapeChat(serverooc).."#"..escapeChat(text.needheader.."(["..(client.id).."] "..name..") in "..getroomname(client.room).." needs "..message:sub(7,-1)..text.needfooter).."\n#%" )
				end
			end
		else
			botmessage(client.socket,text.needhelp)
		end
		return true
	end
	
	if not client.muted and args[1] == "/pm" then
		if tonumber(args[2]) then
			local target = clients[tonumber(args[2])] 
			if target then
				botmessage(client.socket, string.format(text.pmtotarget,target.id,message:sub(5+#args[2]+1,-1)) )
				botmessage(target.socket, string.format(text.pmtosender,client.id,message:sub(5+#args[2]+1,-1)) )
			else
				botmessage(client.socket, text.pmnofind)
			end
			print("Client["..client.id.."] pm'd a message to client["..target.id.."]")
		else
			botmessage(client.socket,text.pmhelp)
		end
		return true
	end
	
	if not client.muted and args[1] == "/coinflip" then
		local result = "Heads"
		local rand = math.random(1,2)
		if rand == 2 then result = "Tails" end
		
		broadcastroom(client.room,"CT#"..escapeChat(serverooc).."#"..escapeChat(name.." flipped a coin and got "..result.."!").."#%")
		return true
	end
	if not client.muted and args[1] == "/roll" then
		local range = tonumber(args[2]) or 6
		local rand = math.random(1,math.max(range,1))
		
		broadcastroom(client.room,"CT#"..escapeChat(serverooc).."#"..escapeChat(name.." rolled a "..range.."-sided die and got "..rand.."!").."#%")
		return true
	end
	if args[1] == "/randomchar" then
		CC(client,math.random(1,#characters))
		return true
	end
	if args[1] == "/switch" then
		local search = string.lower(message:sub(9,-1))
		for i,v in ipairs(characters) do
			if string.lower(v):find(search) then
				if CC(client,i-1) then
					botmessage(client.socket,string.format("Changed character to %s",v))
					return true
				end
			end
		end
		botmessage(client.socket,string.format("Warning: Could not find character with search '%s'",search))
		return true
	end
	
	if args[1] == "/pos" then
		if args[2] then
			local p = string.lower(args[2]:sub(1,3))
			if p == "jud" or p == "wit" or p == "def" or p == "pro" or p == "hld" or p == "hlp" then
				setnewpos(client,p)
				botmessage(client.socket,string.format("Changed position to '%s'",client.pos))
			else
				botmessage(client.socket,"Warning: Invalid position.\nHere is a list of valid positions: def, pro, jud, wit, hld, hlp")
			end
		else
			botmessage(client.socket,"Warning: No position specified!\nHere is a list of valid positions: def, pro, jud, wit, hld, hlp")
		end
		return true
	end
	if args[1] == "/desk" then
		if args[2] then
			if args[2] == "0" or args[2] == "1" or args[2] == "default" then
				client.desk = args[2]
				if args[2] == "default" then client.desk = nil end
				botmessage(client.socket,string.format("Desk changed to %s",args[2]))
			else
				botmessage(client.socket,"Warning: Invalid value!\nAll values: 0, 1, default")
			end
		else
			botmessage(client.socket,"All values: 0, 1, default")
		end
		return true
	end
	
	if args[1] == "/bg" then
		if not client.room.bglock or client.mod then
			for i,v in ipairs(backgrounds) do
				if string.lower(v) == string.lower(args[2]) then
					if client.room.kind ~= "echo" then
						client.room.bg = args[2]
						broadcastroom(client.room,"BN#"..args[2].."#%")
					else
						buffersend(client.socket,"BN#"..args[2].."#%")
					end

					botmessage(client.socket,string.format(text.changedbg,args[2]))
					return true
				end
			end
			botmessage(client.socket,text.invalidbg)
		else
			botmessage(client.socket,"Warning: This room is BG-locked!")
		end
		return true
	end
	
	if not client.muted and args[1] == "/nick" then
		local nick = message:sub(7,-1)
		if args[2] then
			client.nick = nick
			botmessage(client,"Nickname set: "..tostring(client.nick))
		else
			botmessage(client,"Nickname cleared.")
			client.nick = nil
		end
		return true
	end
	
	if not client.muted and args[1] == "/name" then
		local name = message:sub(7,-1)
		if args[2] and client.room.id > staticrooms then
			client.room.name = name
			broadcastroom(client.room,"CT#"..escapeChat(serverooc).."#"..escapeChat("["..client.id.."] updated the courtroom name.").."#%")
		else
			botmessage(client.socket, client.room.name)
		end
		return true
	end
	if not client.muted and args[1] == "/desc" then
		local desc = message:sub(7,-1)
		if args[2] and client.room.id > staticrooms then
			client.room.desc = desc
			broadcastroom(client.room,"CT#"..escapeChat(serverooc).."#"..escapeChat("["..client.id.."] updated the courtroom description.").."#%")
		else
			botmessage(client.socket, client.room.desc)
		end
		return true
	end
	if client.room and client.room.kind == "court" then
		if args[1] == "/status" then
			if args[2] then
				local status = string.upper(args[2])
				if status == "IDLE"
				or status == "BUILDING"
				or status == "RUNNING"
				or status == "RECESS"
				or status == "FINISHED" then
					client.room.status = status
					broadcastroom(client.room,"CT#"..escapeChat(serverooc).."#"..escapeChat("["..client.id.."] changed the room status to ".. status).."#%")
				else
					botmessage(client.socket,"Warning: Invalid status name!\nHere are the valid statuses: IDLE, BUILDING, RUNNING, RECESS, FINISHED")
				end
			else
				botmessage(client.socket,"The room's current status is "..tostring(client.room.status))
			end
			return true
		end
		if args[1] == "/doc" then
			if args[2] and not client.muted then
				if args[2]:find("%w") then
					client.room.doc = args[2]
					broadcastroom(client.room,"CT#"..escapeChat(serverooc).."#"..escapeChat("["..client.id.."] updated the doc link.").."#%")
				else
					client.room.doc = nil
					broadcastroom(client.room,"CT#"..escapeChat(serverooc).."#"..escapeChat("["..client.id.."] removed the doc link.").."#%")
				end
			else
				if client.room.doc then
					botmessage(client.socket,client.room.doc)
				else
					botmessage(client.socket,"There is no doc set!")
				end
			end
			return true
		end
		if args[1] == "/leave" and not client.trapped then
			joinroom(client,1)
			return true
		end
		if args[1] == "/lock" and client.room.id > staticrooms then
			local pass = args[2]
			if pass and pass:find("%S") then
				broadcastroom(client.room,"CT#"..escapeChat(serverooc).."#"..escapeChat("["..client.id.."] locked the courtroom with passcode: '"..pass.."'.").."#%")
				client.room.lock = pass
			end
			return true
		end
		if args[1] == "/unlock" and client.room.id > staticrooms then
			if client.room.lock then
				client.room.lock = false
				broadcastroom(client.room,"CT#"..escapeChat(serverooc).."#"..escapeChat("["..client.id.."] unlocked the courtroom.").."#%")
			end
			return true
		end
		
	end
	
	--Moderator tools
	if args[1] == "/modpass" then
		local pass = message:sub(10,-1)
		for i,v in ipairs(modpasses) do
			if pass == v then
				client.mod = true
				botmessage(client.socket,"Added moderator status.")
				print("Mod["..(client.id).."]["..name.."] entered moderator status.")
				return true
			end
		end
	end
	if client.mod then
		if args[1] == "/mute" then
			local userid = tonumber(args[2])
			if userid then
				local target = clients[userid]
				if target then
					target.muted = true
					botmessage(client.socket,"Muted ["..(target.id).."]")
					print("Mod["..(client.id).."]["..name.."] muted user ["..(target.id).."]")
				else
					botmessage(client.socket,"Warning: Invalid target.")
				end
			end
			return true
		end
		if args[1] == "/unmute" then
			local userid = tonumber(args[2])
			if userid then
				local target = clients[userid]
				if target then
					target.muted = false
					botmessage(client.socket,"Unmuted ["..(target.id).."]")
					print("Mod["..(client.id).."]["..name.."] unmuted user ["..(target.id).."]")
				else
					botmessage(client.socket,"Warning: Invalid target.")
				end
			end
			return true
		end
		if args[1] == "/kick" then
			local userid = tonumber(args[2])
			if userid then
				local target = clients[userid]
				if target then
					botmessage(client.socket,"Kicked ["..(target.id).."]")
					print("Mod["..(client.id).."]["..name.."] kicked user ["..(target.id).."]")
					doclosed(target.socket)
				else
					botmessage(client.socket,"Warning: Invalid target.")
				end
			end
			return true
		end
		if args[1] == "/ban" then
			local userid = tonumber(args[2])
			if userid then
				local target = clients[userid]
				if target then
					botmessage(client.socket,"Banned ["..(target.id).."]. IP: "..tostring(target.ip))
					print("Mod["..(client.id).."]["..name.."] banned user ["..(target.id).."]! IP: "..tostring(target.ip))
					
					table.insert(bans,target.ip)
					doclosed(target.socket)
					savelist(bans,path.."bans.txt")
				else
					botmessage(client.socket,"Warning: Invalid target.")
				end
			end
			return true
		end
		if args[1] == "/unban" then
			local ip = args[2]
			if ip then
				local unbanned = false
				for i=#bans,1,-1 do local v = bans[i]
					if v == ip then
						unbanned = true
						table.remove(bans,i)
					end
				end
				if unbanned then
					savelist(bans,path.."bans.txt")
					botmessage(client.socket,"Unbanned IP: "..tostring(ip))
					print("Mod["..(client.id).."]["..name.."] unbanned ip: "..tostring(ip))
				else
					botmessage(client.socket,"Warning: IP was not found in the list.")
				end
			end
			return true
		end
		if args[1] == "/move" then
			local userid = tonumber(args[2])
			if userid then
				local target = clients[userid]
				if target and tonumber(args[3]) and tonumber(args[3]) >= 0 and tonumber(args[3]) <= #rooms then
					joinroom(target,tonumber(args[3]))
					botmessage(client.socket,"Moved ["..(target.id).."] to room "..args[3])
					print("Mod["..(client.id).."]["..name.."] moved user ["..(target.id).."] to room "..args[3])
				else
					botmessage(client.socket,"Warning: Invalid target or room.")
				end
			end
			return true
		end
		if args[1] == "/trap" then
			local userid = tonumber(args[2])
			if userid then
				local target = clients[userid]
				if target and tonumber(args[3]) and tonumber(args[3]) >= 0 and tonumber(args[3]) <= #rooms then
					target.trapped = true
					joinroom(target,tonumber(args[3]))
					botmessage(client.socket,"Trapped ["..(target.id).."] in room "..args[3])
					print("Mod["..(client.id).."]["..name.."] trapped user ["..(target.id).."] to room "..args[3])
				else
					botmessage(client.socket,"Warning: Invalid target or room.")
				end
			end
			return true
		end
		if args[1] == "/untrap" then
			local userid = tonumber(args[2])
			if userid then
				local target = clients[userid]
				if target then
					target.trapped = false
					botmessage(client.socket,"Un-trapped ["..(target.id).."]")
					print("Mod["..(client.id).."]["..name.."] un-trapped user ["..(target.id).."]")
				else
					botmessage(client.socket,"Warning: Invalid target or room.")
				end
			end
			return true
		end
		if args[1] == "/reload" then
			print("Reloading!")
			for k,v in pairs(viewers) do
				if v and v.socket then
					doclosed(v.socket)
				end
			end
			for k,v in pairs(clients) do
				if v and v.socket then
					doclosed(v.socket)
				else
					print(k,"doesn't exist or has a connection.")
				end
			end
			masterserver:makeHeartbeat()
			reload()
			return true
		end
		if args[1] == "/softreload" then --Only reload some stuff, so nobody gets kicked out.
			print("Soft-Reloading!")
			dofile(path.."settings/settings.lua")
			dofile(path.."settings/features.lua")
			filters = dofile(path.."settings/filters.lua")
			backgrounds = dofile(path.."settings/backgrounds.lua")
			text = dofile(path.."settings/text.lua")
			masterserver:makeHeartbeat()
			botmessage(client.socket,"Soft-Reloaded!")
			return true
		end
		if args[1] == "/muteroom" then --Mutes everyone in the room except mods.
			client.room.roommute = true
			botmessage(client.socket,"Room muted.")
			return true
		end
		if args[1] == "/unmuteroom" then --Mutes everyone in the room except mods.
			client.room.roommute = false
			botmessage(client.socket,"Room unmuted.")
			return true
		end
		if args[1] == "/modlock" then --Make room only open to mods or trapped users.
			botmessage(client.socket,"The current room is now mod locked!")
			client.room.modlock = true
			return true
		end
		if args[1] == "/unmodlock" then
			botmessage(client.socket,"Mod lock removed.")
			client.room.modlock = false
			return true
		end
	end
end

function CC(client,charid) --Change character! I get it!
	if charid and charid >= 0 and charid < #characters then
		--if client.room and client.room.kind ~= "echo" and client.room.chars[charid] then return end --Fail if someone else is already this character!
		
		buffersend(client.socket,"PV#"..client.id.."#CID#"..charid.."#%")
		client.charid = charid
		client.pos = nil
		
		print("Client["..client.id.."] changed character to "..getcharname(charid))
		analytics:track("chars",getcharname(charid))

		return true
	end
end

function setnewpos(client,target)
	local room = client.room
	
	if room and room.kind ~= "echo" then
		local taken = {}
		for k,v in pairs(room.clients) do
			if client.id ~= v.id
			and v.pos ~= nil
			and v.charid == client.charid then
				taken[v.pos] = true
			end
		end
		
		if taken[target] then
			local found = false
			local spots = {"def","pro","wit","hld","hlp","jud"}
			for i,v in ipairs(spots) do
				if not taken[v] then
					found = v
					break
				end
			end
			if found then
				client.pos = found
				botmessage(client.socket,"Warning: This position is already taken by the same character.")
			else
				client.pos = "hld"
				botmessage(client.socket,"Warning: All positions are already taken. Using 'hld'")
			end
		else
			client.pos = target
		end
	else
		client.pos = target
	end
end

function joinroom(client,roomid,r)
	local reason = r or "joined this room." 
	local room = rooms[roomid] 
	if room then
		leaveroom(client,"left to room "..tostring(room.name))
	
		client.room = room
		room.count = room.count + 1
		room.clients[client] = client
	
		buffersend(client.socket,"BN#"..(room.bg).."#%")
		buffersend(client.socket,"MC#"..(room.music).."#-1#%")
		
		if room.kind == "court" then
			buffersend(client.socket,"HP#1#"..room.hp[1].."#%")
			buffersend(client.socket,"HP#2#"..room.hp[2].."#%")
		else
			buffersend(client.socket,"HP#1#0#%HP#2#0#%")
		end
		listevidence(client)

		broadcastroom(room,"CT#"..escapeChat(serverooc).."#"..escapeChat("["..client.id.."] "..reason).."#%")
		return true
	else
		botmessage(client.socket,text.invalidroom)
	end
end

function leaveroom(client,message)
	local msg = message or "left this room."
	if client.room then
		client.pos = nil
		
		local room = client.room
		room.count = room.count - 1
		room.clients[client] = nil
		--print(client.id,"Left room: ",room.id)
		broadcastroom(room,"CT#"..escapeChat(serverooc).."#"..escapeChat("["..client.id.."] "..msg).."#%")
		return true
	end
end

function broadcastroom(room,message)
	for k,v in pairs(room.clients) do
		buffersend(v.socket,message)
	end
end

function getcharname(charid)
	return characters[(charid or -2)+1] or "A spectator"
end
function getroomname(room)
	local name = room and room.name or "Void"
	if room and room.id > staticrooms then name = "\""..name.."\"" end
	return name
end

function getroom(id)
	return rooms[tonumber(id)]
end
function getuser(id)
	return rooms[tonumber(id)]
end

function spamcheck(client,message)
	local result
	local msg = string.lower(string.gsub(message,"%W",""))
	local msgspc = string.lower(message) --Spaces included, so you can check for phrases
		
	for i,v in ipairs(filters) do
		if v:find(" ") and msgspc:find(v) or msg:find(v) then
			result = true
			break
		end
	end
	if result then
		client.spamcounter = client.spamcounter + 5
		return true
	end
end
