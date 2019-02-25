--Handles communication.
local process = ...

local communication = {
	help = {
		{"g","(msg)","Sends a message to everybody in the server."},
		{"pm","(id) (msg)","Sends a private message to a player."},
	}
}

function communication:init()
	process:registerCallback(self,"command",3,self.command)
	process:registerCallback(self,"emote",3,self.emote)
	process:registerCallback(self,"ooc", 5,self.trackOOCname)
	process:registerCallback(self,"ooc", 1,self.message)
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
			process:sendMessage(client,msg or "","PM to ["..id.."]")
			process:sendMessage(target,msg or "","PM from ["..id.."]")
		else
			process:sendMessage(client,"Couldn't find player with that ID.")
		end
		return true
	end
end

function communication:trackOOCname(client, ooc)
	if ooc.name then
		ooc.name = ooc.name:match("^%s*(.-)%s*$")

		client.name = ooc.name
	end
	if not ooc.name then ooc.name = client.character end
end
function communication:message(client, ooc)
	for player in process:eachPlayer() do
		if player ~= client and ooc.name == player.name then
			process:sendMessage(client,"Your nickname is already in use!")
			return true
		end
	end

	ooc.name = "["..client.id.."] ".. ooc.name
	if client.mod then
		ooc.name = "[Mod]".. ooc.name
	end
end

function communication:emote(client, emote)
	if emote.name then 
		emote.name = emote.name:match("^%s*(.-)%s*$")
		
		client.showname = emote.name
	end
	if not emote.name then
		emote.name = emote.character

	else --Ignore check if the user is not using any shownames
		for player in process:eachPlayer() do
			if player ~= client
			and (emote.name == player.showname or emote.name == player.name) then
				process:sendMessage(client,"Your showname is already in use!")
				return true
			end
		end
	end
end

return communication