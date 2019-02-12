--Handles character selecting, and related functions.
local process = ...

local charhelper = {
	help = {
	}
}

function charhelper:init()
	process:registerCallback(self,"player_done",3,self.player_done)
	process:registerCallback(self,"command",3,self.command)
	process:registerCallback(self,"emote",3,self.emote)
	process:registerCallback(self,"character_pick",3,self.character_pick)
end

function charhelper:command(client, cmd,str,args)
	if cmd == "" then
	
	end
end

function charhelper:emote(sender, emote)
end

function charhelper:character_pick(client, name)

end

function charhelper:player_done(client)
	client:send("CHAR_PICK",{character = -1})
end

return charhelper