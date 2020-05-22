local process = ...

local iniswap = {
	name = "iniswap",

	help = {
		{"iniswap","(character)","Sets your iniswapped character.","'/is' can be used as a shorthand. This command only works for rooms that allow iniswapping."},
	}
}

function iniswap:init()
	process:registerCallback(self,"command",3,self.command)
	process:registerCallback(self,"character_pick",3,self.pick)
end

--TODO: Handle iniswapped players entering other rooms.
function iniswap:command(client, cmd,str,args)
	if cmd == "iniswap" or cmd == "is" then
		if not client.room or not client.room.iniswap then
			process:sendMessage(client,"Ini-swapping isn't allowed in this room!")
			return true
		end

		process:send(client,"CHAR_REQ",{character=client.character})

		local name = string.lower(str)
		client.character = name
		client.iniswapped = true
		process:sendMessage(client,"Set iniswap to '"..name.."'")
		process:sendMessage(client, config[cmd])
		return true
	end
end

function iniswap:pick(client,character)
	client.iniswapped = false
end

return iniswap
