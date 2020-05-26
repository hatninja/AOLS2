--Handles character selecting, and related functions.
local process = ...

local charhelper = {
	help = {
		{"char","(name)","Picks a character."},
		{"charlist","","The list of available characters."},
		{"randomchar","","Picks a random character."}
	}
}

function charhelper:init()
	process:registerCallback(self,"player_done",3,self.player_done)
	process:registerCallback(self,"command",3,self.command)
	process:registerCallback(self,"emote",4,self.emote)
	process:registerCallback(self,"character_pick",3,self.character_pick)
end

function charhelper:command(client, cmd,str,args)
	if cmd == "char" then
		local characters = process.characters
		for i,char in ipairs(characters) do
			if string.lower(str) == string.lower(char:getName()) then
				process:send(client,"CHAR_REQ",{character=str})
				process:sendMessage(client,"Picked '"..str.."'")
				return true
			end
		end
		process:sendMessage(client,"Could not find '"..str.."'")
		return true
	end
	if cmd == "charlist" then
		local list = ""
		local characters = process.characters
		for i,char in ipairs(characters) do
			local name = char:getName()
			list = list .. name .. ", "
		end
		list = list:sub(1, -3)
		process:sendMessage(client,list)
		return true
	end
	if cmd == "randomchar" then
		local characters = process.characters
		local rand = math.random(1,#characters)
		local char = characters[rand]
		local name = char:getName()
		process:send(client,"CHAR_REQ",{character=name})
		process:sendMessage(client,"Picked '"..name.."'")
		return true
	end
end

function charhelper:character_pick(client, name)
	--Block if a character isn't found in the character list.
	for i,v in ipairs(process.characters) do
		if string.lower(name) == string.lower(v:getName()) then
			return
		end
	end
	return true
end

function charhelper:emote(client, emote)
	if not config.iniswap then
		emote.character = client.character
	end
end


function charhelper:player_done(client)
	if config.autospectate then
		client:send("CHAR_PICK",{character = -1})
	end
end

return charhelper
