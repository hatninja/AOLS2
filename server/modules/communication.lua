--Handles communication and also houses anti-impersonation features.
local process = ...

local communication = {
	help = {
		{"g","(msg)","Sends a message to everybody in the server."},
		{"pm","(id) (msg)","Sends a private message to a player."},
	}
}

function communication:init()
	process:registerCallback(self,"command",3,self.command)
	process:registerCallback(self,"ooc", 1,self.prefix)
	process:registerCallback(self,"ooc", 5,self.trackOOCname)
	process:registerCallback(self,"music_play", 4,self.trackshowname)
	process:registerCallback(self,"emote", 4,self.trackshowname)
	process:registerCallback(self,"player_move", 0,self.removeshowname)
	process:registerCallback(self,"emote", 6,self.emote)
end

function communication:command(client, cmd,str,args, oocname)
	if cmd == "g" then
		local name = "["..client.id.."]"
		local msg = str
		if client.room then
			name=name.."["..tostring(client.room.name).."]"
		end
		if client.name then
			name = name .." ".. client.name
		else
			name = name .." ".. tostring(oocname or client.character)
		end
		for player in process:eachPlayer() do
			process:sendMessage(player,msg,name)
		end
		return true
	end
	if cmd == "pm" then
		local id, msg = str:match("(%d+)%s(.+)")
		id = tonumber(id)
		local target = process:getPlayer(id)
		if target then
			process:sendMessage(client,msg or "","PM to ["..id.."] "..(client.name or ""))
			process:sendMessage(target,msg or "","PM from ["..tostring(client.id).."] "..(oocname or ""))
		else
			process:sendMessage(client,"Couldn't find player with that ID.")
		end
		return true
	end
end

function communication:prefix(client, ooc)
	ooc.name = "["..client.id.."] ".. ooc.name
	if client.mod then
		ooc.name = "[Mod]".. ooc.name
	end
end
function communication:trackOOCname(client, ooc)
	if ooc.name then
		ooc.name = ooc.name:match("^%s*(.-)%s*$")

		for player in process:eachPlayer() do
			if player ~= client

			and player.ip ~= client.ip
			and player.hardwareid ~= client.hardwareid

			and (ooc.name == player.name or ooc.name == player.showname) then
				process:sendMessage(client,"Your nickname is already in use!")
				return true
			end
		end

		--Prevent using a nickname to block normal character names.
		for i,char in ipairs(process.characters) do
			local charname = char:getName()
			if charname == ooc.name then
				return
			end
		end

		client.name = ooc.name
	end
end

function communication:trackshowname(client, emote)
	if not emote.name then
		emote.name = emote.character
	end
	if emote.name then 
		emote.name = emote.name:match("^%s*(.-)%s*$")

		--Allow same shownames if in different rooms, but never allow a showname of a username.
		for player in process:eachPlayer() do
			if player ~= client
			and ((player.room == client.room and emote.name == player.showname)
			or (emote.name == player.showname)) then
				process:sendMessage(client,"Your showname is already in use!")
				return true
			end
		end

		--Prevent using a showname to remotely block other characters.
		if emote.name ~= emote.character then
			for i,char in ipairs(process.characters) do
				local charname = char:getName()
				if charname == emote.name then
					return
				end
			end
		end
	
		client.showname = emote.name
	end
end
function communication:removeshowname(client)
	client.showname = nil
end

function communication:emote(client,emote)
	if client.room then
		local room = client.room
	end
end

return communication