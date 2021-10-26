--AOWriter: Write games in AO!
local process = ...

local PERM_VIEWER,PERM_PLAYER,PERM_WRITER,PERM_AUTHOR = 1,2,3,4
local RECEIVEMAX = 4000 --Should be just below server's maximum. server.lua uses 4096, leaving 96 bytes of leeway for protocols.

local CODE = {
	"SPEAK", --Character Emote. Blank for blankpost.

	--Control Flow:
	"WAIT",
	"SET",
	"IF",
	"GOTO",


	--
	"RECYCLE", --Marks a flag for recycling. This lets the trimmer reuse this flag for other purposes.
	           --The value will not change however, be sure to clear the variable before use.

	--Non-char effects:
	"W", --Woosh. (wt,ce,enp,dip,g,ng) "enp": enable prompt, "dip": disable prompt.


	--Scene settings
	"BG", --(BG name), (pos), Maybe can have shorthand pos setting? Zoom bg could be hardcoded.
	"POS", --(pos)
	"FG", --(fg to enable) Foreground enable/disable. Disables fg if no argument.

	--Emote settings.
	"FX", --Effect setting, like realization. Cleared after speak.
	"SFX", --Set sound effect and timing. Cleared after speak.

	"CHAR", --Char: (Character), (Emote), (Pre), (Show)
	"SHOW", --Change showname.
	"EMOTE", --(emote), (pre), (sfx), (sfx_t) Change talk animation.
	"PRE", --Change pre animation.
	"SKIP", --Message will continue unpaused.
	"APPEND", --Message will append to last.
	"CLEAR", --Set emote settings to default.
}
for i,v in ipairs(CODE) do
	CODE[v] = i
end



--Now the actual module begins!
local aowriter = {
	help = {
		{"wOpen","(game id)","Start a new AOWriter session."}, --Two write sessions can edit the game if they so choose.
		{"wJoin","(session id)","Join a session if it exists."},
		{"wGame","","See all games stored listed by id."},
		{"wImport","","Import an AOWrite game."},
	}
}

function aowriter:init()
	self.games = {
		{
			name = "Turnabout Test",
			auth = "Smol",
			vers = "0",

			chars = {"Phoenix","Edgeworth","Judge","Maya","Gumshoe"},
			emotes = {"deskslam","normal","zoom"},
			music = {"AA/Trial.ogg","AA/Lobby.ogg","AA/Pursuit.ogg"},
			bg = {"court/AA","backdrop/LobbyAA"},
			sfx = {"sfx-deskslam"},

			script = {
				{"BG"}, --Just have empty background, i guess.
				{"SPEAK","~~Intro: 20XX.\nJapanifornia."}, --COLOR? APPEND, SKIPWAIT, SHOWNAME.
				{"CHAR","Phoenix"},
				{"SHOW","Mr. Wright"}, --Store shownames per character?
				{"EMOTE","normal"},
				{"PRE","deskslam"},
				{"SFX","sfx-deskslam",6},
				{"SPEAK",nil},
				{"WAIT",0.5},
				{"MUS","AA/Pursuit.ogg"},
				{"SPEAK","\\fI am Mr. Wright!!"},
			}
		},

	}
	self:load()

	self.sessions = {}

	process:registerCallback(self,"command",3,self.command)
	process:registerCallback(self,"ooc",6,self.getimport) --Override OOC to get game data.
	process:registerCallback(self,"music_play", 4,self.trackmusic)
	process:registerCallback(self,"emote", 4,self.trackwrite)
	process:registerCallback(self,"player_move", 0,self.trackmove)
end

--[[Server Storage]]
function aowriter:addgame(game)
	self.games[#self.games+1] = game

	local f = io.open(path.."data/writer/"..(#self.games+1)..".txt","w")
	f:write(self:writegame(game))
	f:close()

	local f = io.open(path.."data/writer/games.txt","w")
	f:append((#self.games).."\n")
	f:close()
end
function aowriter:load()
	--Load all games from list, and dynamically write away missing files from the list.
	local t = process:loadList(path.."data/writer/games.txt")
	for i,v in ipairs(t) do
		local file = io.open(path.."data/writer/"..v..".txt","r")
		if file then
			local data = file:read("a*")
			file:close()

			local game,err = self:loadgame(data)
			if game then
				local file = io.open(path.."data/writer/"..tostring(#self.games+1)..".txt","w")
				file:write(data)
				file:close()
				self.games[#self.games+1]=game
				self:print("Loaded game: "..game.name.." - "..game.vers.." by "..game.auth)
			else
				self:print("Error loading game '"..v.."' "..err)
			end
		end
	end
	--Write new list.
	local f = io.open(path.."data/writer/games.txt","w")
	local l = ""
	for i=1,#self.games do
		l=l..i.."\n"
	end
	f:write(l)
	f:close()
end

--[[Game Serialization]]
function aowriter:writegame(game,encoded)
	local data = ""
	data = data .. game.name .. "|"
	data = data .. game.vers .. "@"

	if not encoded then
		data = data.."\n"
	end
	local body = ""

	return data..body
end
function aowriter:loadgame(data)
	local game = self:newgame()
	if not data or data < 4 then return nil, "No game data found!" end

	local encoded = false
	local st,en = data:find("@\n")
	if not st then
		st,en = data:find("@")
		if st then
			encoded = true
		end
	end
	if not st then return nil, "Missing body!" end

	local header = data:sub(1,st-1)
	local body = data:sub(en+1,-1)

	game.name = header:match("$.-%|") or "???"
	game.vers = header:match("%|.-^") or "???"

	return game
end

--[[Importing & Exporting]]
function aowriter:clone(game,tclone)
	local g = {}
	for k,v in pairs(game) do
		if type(v) == "table" then
			g[k] = self:clone(v,true)
		else
			g[k] = v
		end
	end
	return g
end

function aowriter:trim(game)
	local g = self:clone(game)
	return g
end

function aowriter:getimport(client, msg)
	if not client.doimport then return end
	local game = self:importcode()
	if game then
		process:sendMessage(client,"Imported game! You can find it in the server's directory.")
	else
		process:sendMessage(client,"Import failed! The code may be invalid.")
	end
	client.doimport = false

	return true
end

function aowriter:copy(client,game)
	local g = self:clone(game)
	g.authip = client and (client.ipid or client.ip)

	self:addgame(g)
end

--[[Game & Session Structure]]
function aowriter:newgame(client)
	local game = {}
	game.name = "Untitled"
	game.vers = "pre"
	game.auth = client and client.name or ""

	game.chars = {}
	game.emotes = {}
	game.music = {}
	game.sfx = {}
	game.bg = {}

	game.script = {
		["Intro"]={}
	}

	game.lastlabel = "Intro"
	game.lastpos = 1

	game.authip = client and (client.ipid or client.ip)
	game.lock = true

	return game
end
function aowriter:newsession(game,client,write)
	local ses = {}
	ses.game = game

	ses.users = {}
	ses.users[client] = {write and PERM_WRITER or PERM_PLAYER,"play"}

	ses.gm = client

	ses.flags = {}
	ses.label = "Intro"
	ses.pos = 1

	ses.req = {}
	ses.invited = {}
	ses.jperm = 1

	ses.private = 0

	return ses
end

--[[Commands]]
function aowriter:command(client, cmd,str,args, oocname)

	if self:globalcommands(client, cmd,str,args, oocname) then return true end
	if client.wses and self:sessioncommands(client, cmd,str,args, oocname) then return true end

end

function aowriter:globalcommands(client, cmd,str,args, oocname)
	if cmd == "wO" or cmd == "wOpen" then
		local game
		local newgame = false
		if args[1] then
			local id = tonumber(args[1]) or -1
			if not self.games[id] then
				process:sendMessage(client,"[AOW] Could not find game with that ID!\nMake sure you are using the numerical identifier seen in /wG.")
				return true
			end
			game = self.games[id]
			process:sendMessage(client,"[AOW] Opening game: "..tostring(game.name).." - "..tostring(game.vers).."\nBy: "..tostring(game.auth))
		else
			game = self:newgame(client)
			newgame = true
			process:sendMessage(client,"[AOW] No argument. Generating new game!")
		end
		local ses = self:newsession(game,client,newgame)

		local sesid = #self.sessions+1
		ses.sesid = sesid
		self.sessions[sesid] = ses

		client.wses = ses

		local msg = "[AOW]"..(client:getIdent()).." started an AOWriter session!"
		process:sendMessage(client.room or process,msg)
		process:sendMessage(client,"[AOW] Session ID: "..sesid)
		self:print(msg)

		return true
	end
	--Join session.
	if cmd == "wJ" or cmd == "wJoin" then
		local id = tonumber(args[1]) or -1
		if self.sessions[id] then
			local ses = self.sessions[id]
			if self:joinsession(client,ses) then
				process:sendMessage(client,"[AOW] Joined session!")
				self:broadcast(ses,"[AOW] "..client:getIdent().." joined the session!")
			else
				process:sendMessage(client,"[AOW] Join failed!")
			end
		else
			process:sendMessage(client,"[AOW] Could not find session with that ID!\nMake sure you are using the numerical identifier seen in /wS.")
		end
		return true
	end
	--Game info
	if cmd == "wG" or cmd == "wGame" then
		local msg = "[AOW] List of games:"
		for i,v in pairs(self.games) do
			msg=msg.."\n".."["..i.."] "..tostring(v.name)
			msg=msg.."\nVersion: "..tostring(v.vers)
			msg=msg.."\nAuthor: "..tostring(v.auth)
		end
		process:sendMessage(client,msg)
		return true
	end

	if cmd == "wImport" then
		process:sendMessage(client,"[AOW] Importing & Exporting is not a supported feature yet!")
		return true
	end
end

function aowriter:sessioncommands(client, cmd,str,args, oocname)
	local ses = client.wses
	if cmd == "wHelp" then
		local help = "~~AOWriter Session Help~~\n"
		help=help.."Game:\n"
		help=help.."/wTitle - View or change game title.\n"
		help=help.."/wAuthor - View or change author string.\n"
		help=help.."/wVersion - View or change version string.\n"

		help=help.."Session Management:\n"
		help=help.."/wInfo - Session and game info.\n"
		help=help.."/wUsers - View users in current session.\n"
		help=help.."/wLeave - Leave the session.\n"

		help=help.."GM:"
		help=help.."/wAccept - Accept a user's perm request.\n"
		help=help.."/wDeny - Deny a user's perm request.\n"
		help=help.."/wKick - Kick a user.\n"
		help=help.."/a - Get or transfer authorship."

		help=help.."Playing:"
		help=help.."/p - Play mode. Requires Player permission."
		help=help.."> - Progress dialogue."
		help=help..">(num) - "
		help=help.."/w - Write mode. Requires Writer permission."
		help=help.."/v - View mode."
		process:sendMessage(client,help)
		return true
	end
	if cmd == "wTitle" then
		if not args[1] then
			process:sendMessage(client,"[AOW] Game title: "..ses.game.name)
			return true
		end
		if args[1] and self:checkPerm(PERM_AUTHOR,client) then
			ses.game.name = str
			process:sendMessage(client,"[AOW] Set title to: "..str)
			self:broadcast(ses,"[AOW] "..client:getIdent().." changed the title to '"..str.."'",client)
		else
			process:sendMessage(client,"[AOW] Insufficient permissions!")
		end
		return true
	end
	if cmd == "wAuthor" then
		if not args[1] then
			process:sendMessage(client,"[AOW] Game author: "..ses.game.auth)
			return true
		end
		if args[1] and self:checkPerm(PERM_AUTHOR,client) then
			ses.game.auth = str
			process:sendMessage(client,"[AOW] Set author to: "..str)
			self:broadcast(ses,"[AOW] "..client:getIdent().." changed the author to '"..str.."'",client)
		else
			process:sendMessage(client,"[AOW] Insufficient permissions!")
		end
		return true
	end
	if cmd == "wVersion" then
		local msg = "[AOW] "
		if not args[1] then
			process:sendMessage(client,"[AOW] Game version: "..ses.game.vers)
			return true
		end
		if args[1] and self:checkPerm(PERM_AUTHOR,client) then
			ses.game.vers = str
			process:sendMessage(client,"[AOW] Set version info to: "..str)
			self:broadcast(ses,"[AOW] "..client:getIdent().." changed the version to '"..str.."'",client)
		else
			process:sendMessage(client,"[AOW] Insufficient permissions!")
		end
		return true
	end
	if cmd == "wInfo" or cmd == "wI"  then
		process:sendMessage(client,"Title: "..ses.game.name)
		process:sendMessage(client,"Author: "..ses.game.auth)
		process:sendMessage(client,"Version: "..ses.game.vers)
		process:sendMessage(client,"Game Lock: "..tostring(ses.game.lock))
		process:sendMessage(client,"Session ID: "..ses.sesid)
		return true
	end
	if cmd == "wUsers" or cmd == "wU" then
		local msg = "[AOW] Users in session:"
		for cl,v in pairs(ses.users) do
			msg=msg.."\n"..cl:getIdent().." - "
			if self:checkPerm(PERM_AUTHOR,client) then
				msg=msg.."Author"
			elseif self:checkPerm(PERM_WRITER,client) then
				msg=msg.."Writer"
			elseif self:checkPerm(PERM_PLAYER,client) then
				msg=msg.."Player"
			elseif self:checkPerm(PERM_VIEWER,client) then
				msg=msg.."Viewer"
			else
				msg=msg.."Invalid"
			end

			if self:isGM(cl,ses) then
				msg=msg.." [GM]"
			end
			local mode = ses.users[cl][2]
			msg=msg.." ("..mode..")"
		end

		process:sendMessage(client,msg)
		return true
	end
	if cmd == "wLeave" then
		self:broadcast(ses,"[AOW] "..client:getIdent().." left the session!")
		self:leavesession(client,ses)
		return true
	end

	--Mode Switching
	if cmd == "w" then
		if self:checkPerm(PERM_WRITER,client) then
			ses.users[client][2] = "write"
			process:sendMessage(client,"[AOW] Write mode.")
		else
			ses.req[client] = 3
			process:sendMessage(client,"[AOW] Invalid permissions, requesting to write.")
			self:broadcast(ses,"[AOW] "..client:getIdent().." is requesting permissions to write!")
		end
		return true
	end
	if cmd == "p" then
		if self:checkPerm(PERM_PLAYER,client) then
			ses.users[client][2] = "play"
			process:sendMessage(client,"[AOW] Play mode.")
		else
			ses.req[client] = 2
			process:sendMessage(client,"[AOW] Invalid permissions, requesting to play.")
			self:broadcast(ses,"[AOW] "..client:getIdent().." is requesting permissions to play!")
		end
		return true
	end
	if cmd == "v" then
		ses.users[client][2] = "view"
		process:sendMessage(client,"[AOW] View mode.")
		return true
	end

	--User management
	if cmd == "wAccept" then
		local cl = process:getPlayer(tonumber(args[1]) or -1)
		if cl and self:isGM(client,ses) then
			if ses.req[cl] then
				ses.users[cl][1] = ses.req[cl]
				ses.req[cl] = nil
				self:broadcast(ses,"[AOW] "..cl:getIdent().."'s request was granted!")
			end
		end
		return true
	end
	if cmd == "wDeny" then
		local cl = process:getPlayer(tonumber(args[1]) or -1)
		if self:isGM(client,ses) and cl and ses.req[cl] then
			ses.req[cl] = nil
			self:broadcast(ses,"[AOW] "..cl:getIdent().."'s request was denied!")
		end
		return true
	end
	if cmd == "wKick" then
		local cl = process:getPlayer(tonumber(args[1]) or -1)
		if self:isGM(client,ses) == client and cl then
			self:broadcast(ses,"[AOW] "..cl:getIdent().." was kicked from the session!")
			self:leavesession(cl,ses)
		end
		return true
	end
	if cmd == "a" then
		if (self:checkPerm(PERM_AUTHOR,client) or client.mod) and (ses.authip == client.ip or ses.authip == client.ipid) or not ses.lock then
			local pl = process:getPlayer(args[1])
			if pl then
				game.authip = pl.ipid or pl.ip
				self:broadcast(ses,"[AOW] Authorship transferred to "..pl:getIdent())
				return true
			end

			ses.users[client][1] = PERM_AUTHOR
			process:sendMessage(client,"[AOW] Author permissions granted.")
		else
			process:sendMessage(client,"[AOW] Author permissions denied.")
		end
		return true
	end

	--[[Information]]
	if cmd == "wLabels" or cmd == "wL" then
		local msg = "[AOW] Labels:"
		for label,script in pairs(ses.script) do
			local lines = 0
			local count = 0
			for i,v in ipairs(script) do
				if v[1] ~= "HIDDEN" then
					count=count+1
				end
				if v[1] == "SPEAK" then
					lines = lines + 1
				end
			end
			msg=msg.."\n\'"..label.."\': "..lines.." Lines - "..count.." Cmds"
		end
		process:sendMessage(client,msg)
		return true
	end

	--[[Navigation]]
	--Script manipulation.
	if cmd == "wJump" or cmd == "wJ" then --Jump label or position.
	end
	--Remove command.
	if cmd == "wRem" then
	end
	if cmd == "wHide" then --Disables or enables a line in the script.
	end
	--
	if cmd == "wAdd" then
	end
	--Print current script within a range.
	if cmd == "wScript" then --(starting) [ending] - By default, maybe a radius of 5 commands before and after (starting).
	end


	--Script Recording
	if cmd == "wBG" then
	end

	if cmd == "wLock" or cmd == "wK" then
		if not (self:checkPerm(PERM_AUTHOR,client) or client.mod) then return end
		ses.game.lock = not ses.game.lock
		if ses.game.lock then
			process:sendMessage(client,"[AOW] Game lock disabled.")
		else
			process:sendMessage(client,"[AOW] Game lock enabled.")
		end
		return true
	end
end



function aowriter:checkPerm(p,client,ses)
	local ses = ses or client.wses
	if not ses then error("Checked permissions for user with no session!",2) end

	local mode = ses.users[client]
	if mode[1] >= p then return true end
end
function aowriter:getMode(client,ses)
	local ses = ses or client.wses
	if not ses then error("Checked mode for user with no session!",2) end

	local mode = ses.users[client]
	return mode[2]
end
function aowriter:broadcast(ses,msg,client,p)
	for cl,v in pairs(ses.users) do
		if cl ~= client
		and (p and self:checkPerm(p,client,ses) or true) then
			process:sendMessage(cl,msg)
		end
	end
end
function aowriter:joinsession(client, ses)
	if ses then
		ses.users[client] = {ses.jperm,"view"}
		client.wses = ses
		return true
	end
end
function aowriter:leavesession(client)
	if client.wses then
		self:broadcast(client.wses,"[AOW] "..client:getIdent().." left the session!")
		client.wses.users[client] = nil
		client.wses = nil
	end
end
function aowriter:updatesessions()
	for i=1,#self.sessions do
		local ses = self.sessions[i]
		if ses then
			local userspresent = false
			for k,v in pairs(ses.users) do
				userspresent = true
			end
			if not userspresent then
				if not ses.idletime then
					ses.idletime = 0
				end
				ses.idletime = ses.idletime + config.rate
				if ses.idletime > 60 then
					self.sessions[i] = nil
				end
			end
		end
		self:updatesession(ses)
	end
end
function aowriter:updatesession(ses)
	local gmfound = false
	for cl,v in pairs(ses.users) do
		if cl:isClosed() then
			ses.users[cl] = nil
		end
	end
end

function aowriter:setGM(ses,cl)
	if cl then
		ses.gm = cl
		self:broadcast(ses,"[AOW] The session's GM is now "..cl:getIdent())
	end
end
function aowriter:isGM(client,ses)
	return ses.gm == client
end

--[[Track events so they can be written!]]
function aowriter:trackmusic(client, ooc)

end

function aowriter:trackwrite(client, emote)
	--Track lastbg. This is so your background is preserved even if you are viewing a game.
end

function aowriter:trackmove(client)
	--Track lastbg. This is so your background is preserved even if you are viewing a game.
end






















--[[
Encoding nonsense
]]
--[[Originally, i wanted to use all printable ascii characters.
I gave up trying to make this work, so it's base64 now.]]

--All printable ascii characters, for easy copy-pasting.
local asciidigits = "!\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
local asciibase = #asciidigits
local encodeascii = function(str)
	local output = {}
	local value = 0
	local i = 1
	while i <= #str or value > 0 do
		local c = i<=#str and str:sub(i,i):byte() or 0

		value = value + c
		local rem = (value % asciibase) + 1 --Like grabbing bits with & to get the relevant value.
		table.insert(output,#output+1,asciidigits:sub(rem,rem))

		value = math.floor(value / asciibase)
		i=i+1
	end
	return table.concat(output,"")
end
local decodeascii = function(str)
	local strc = {}
	for i=1,#str do
		strc[i] = str:sub(i,i):byte()-33
	end

	local output = {}
	local value = 0


	--Multiply output
	local carry = 0
	for i=1,asciibase do --The multiplier
		for j=1,#output do
			local a = output[j] + output[j] + carry
			local r = a % 256
			carry = math.floor(a / 256)
			output[j] = r
		end
		if carry > 0 then
			output[#output+1] = carry
			carry = 0
		end
	end
	--[[
	for i=1,#str,2 do
		local c = 0
		c = c + strc[i]
		if i < #strc then c = c + strc[i+1]*asciibase end
		value = value + c

		local rem = value % 256
		local carry = math.floor(value / 256)

		value = carry

		table.insert(output,#output+1,string.char(rem))
	end]]
	return table.concat(output,"")
end

local encoded = encodeascii("123456789 Hello World!")
print(encoded)
print(decodeascii(encoded))
--[[Base64 from lua users wiki]]
-- character table string
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local function enc(data)
    return ((data:gsub('.', function(x)
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end
local function dec(data)
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end



return aowriter
