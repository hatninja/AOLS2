--Handles iniswap features.
local process = ...

local iniswap = {
	name = "iniswap",

	help = {
		--{"iniswap","(character)","Sets your iniswapped character.","'/is' can be used as a shorthand. This command only works for rooms that allow iniswapping."},
	}
}

function iniswap:init()
	--process:registerCallback(self,"command",3,self.command)
	process:registerCallback(self,"emote",4.1,self.emote) --Relative to charhelper.
	process:registerCallback(self,"character_pick",3,self.pick)
end

--[[function iniswap:command(client, cmd,str,args)
	if cmd == "iniswap" or cmd == "is" then
		if not client.room or not client.room.iniswap then
			process:sendMessage(client,"Ini-swapping isn't allowed in this room!")
			return true
		end

		if not str then
			process:sendMessage(client,"No character given!")
			return true
		end

		local name = string.lower(str)

		if client.software == "AO2" then
			client:send("CHAR_PICK",{character=client.character})
		else
			client:send("CHAR_PICK",{character=name})
		end

		client.character = name
		client.iniswapped = true
		process:sendMessage(client,"Set iniswap to '"..name.."'")
		return true
	end
end]]

function iniswap:pick(client,character)
	client.iniswapped = false
end

function iniswap:emote(client,emote)
	for i,v in ipairs(process.characters) do
		if string.lower(emote.character) == string.lower(v:getName()) then
			return
		end
	end

	if not client.room or not client.room.iniswap then
		process:sendMessage(client,"Ini-swapping isn't allowed in this room!")
		return true
	end

	client.character = emote.character
	client.iniswapped = true
end
return iniswap
