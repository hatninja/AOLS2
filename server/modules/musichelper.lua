local process = ...

local rooms = {
	name = "Music",
}

function rooms:init()
	self.parent = process.modules["rooms"]

	process:registerCallback(self,"command", 3,self.command)
	process:registerCallback(self,"music_play", 5,self.musicbutton)
end

function rooms:musicbutton(client, music)
	music.looping = true
end

function rooms:command(client, cmd,str,args)
	if cmd == "play" then
	end
end

return rooms
