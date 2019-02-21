--Handles character selecting, and related functions.
local process = ...

local bghelper = {
	help = {
		{"bg","(name)","Changes the room's background."},
		{"bglist","","The list of available backgrounds."}
	}
}

function bghelper:init()
	process:registerCallback(self,"command",3,self.command)
end

function bghelper:command(client, cmd,str,args)
	if cmd == "bg" then
		local backgrounds = process.backgrounds
		for i,bg in ipairs(backgrounds) do
			local name = bg
			if string.lower(name) == string.lower(str) then
				process:sendMessage(client.room or process,"["..client.id.."] changed bg to '"..name.."'")
				if client.room then
					client.room.bg = name
					for i,v in pairs(client.room.players) do
						v:send("BG",{bg = name})
					end 
				end
				return true
			end
		end
		process:sendMessage(client,"'"..str.."' isn't available!")
		return true
	end
	if cmd == "bglist" then
		local list = ""
		local backgrounds = process.backgrounds
		for i,bg in ipairs(backgrounds) do
			list = list .. bg .. ", "
		end
		list = list:sub(1, -3)
		process:sendMessage(client,list)
		return true
	end
end

function bghelper:character_pick(client, name)

end

function bghelper:emote(sender, emote)
	if not emote.name then emote.name = emote.character end
end


function bghelper:player_done(client)
	if config.autospectate then
		client:send("CHAR_PICK",{character = -1})
	end
end

return bghelper