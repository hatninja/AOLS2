--Handles emote features, and implements other emote commands.
local process = ...

local emotehelper = {
	help = {
		{"pos","(def, pro, jud, wit, hld, hlp, jur)","Change the character's position."},
		{"desk","(1, 0, chat)","Changes desk status."},
		{"zoom","","Toggles zoom effect."},
	}
}

function emotehelper:init()
	process:registerCallback(self,"command",3,self.command)
	process:registerCallback(self,"emote",3,self.handle)
	process:registerCallback(self,"character_pick",3,self.resetside)
end

function emotehelper:command(client, cmd,str,args)
	if cmd == "pos" then
		local arg = string.lower(tostring(str))
		local side
		if arg:sub(1,3) == "def" then side = SIDE_DEF
		elseif arg:sub(1,3) == "pro" then side = SIDE_PRO
		elseif arg == "jud" or arg == "judge" then side = SIDE_JUD
		elseif arg == "wit" or arg == "witness" then side = SIDE_WIT
		elseif arg == "hld" or arg == "helper" then side = SIDE_HLD
		elseif arg == "hlp" then side = SIDE_HLP
		elseif arg:sub(1,3) == "jur" then side = SIDE_JUR
		end
		if side then
			if process:event("pos",client,side) then
				client.side = side
				process:sendMessage(client,"Changed position!")
			else
				process:sendMessage(client,"Cannot change position!")
			end
		else
			process:sendMessage(client,"Invalid side name!")
		end
		return true
	end
	if cmd == "desk" then
		if args[1] then
			client.desk = args[1] == "1"
			if args[1] == "default" or args[1] == "chat" then client.desk = nil end

			local msg = "Desk is now forced on."
			if client.desk == false then
				msg = "Desk is now forced off."
			elseif client.desk == nil then
				msg = "Desk is now default."
			end
			process:sendMessage(client,msg)
		else
			process:sendMessage(client,"Use 0, 1, or chat (default)")
		end
		return true
	end
	if cmd == "zoom" then
		client.zoom = not client.zoom
		if client.zoom then
			process:sendMessage(client,"Speedlines are on!")
		else
			process:sendMessage(client,"Speedlines are off!")
		end
		return true
	end
end

function emotehelper:handle(sender, emote)
	--Pos override
	if emote.side and not sender.side then
		sender.side = emote.side
	end
	emote.side = sender.side

	--Desk override
	if sender.desk ~= nil then
		emote.fg = sender.desk
	end

	--Zoom override
	if sender.zoom == true then
		emote.bg = "defense_speedlines"
		if emote.side == SIDE_WIT or emote.side == SIDE_PRO or emote.side == SIDE_HLP then
			emote.bg = "prosecution_speedlines"
		end
	end
end

function emotehelper:resetside(client, name)
	if client.character ~= name then
		client.side = nil
	end
end

return emotehelper