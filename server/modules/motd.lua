local process = ...

local motd = {
	name = "MOTD",

	help = {
		{"motd","","Repeats the welcome message."},
		{"rules","","Read the rules."},
		{"files","","Gets link to server files."},
	}
}

function motd:init()
	process:registerCallback(self,"player_join",0,self.welcome)
	process:registerCallback(self,"command",3,self.command)
end

function motd:welcome(player)
	--self:print("Welcome message sent to ["..player.id.."]!")
	if config.motd then
		process:sendMessage(player,config.motd)
	end
end

function motd:command(client, cmd,str,args)
	if cmd == "motd" or cmd == "rules" or cmd == "files" then
		process:sendMessage(client, config[cmd])
		return true
	end
end

return motd