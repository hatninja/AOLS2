local process = ...

local music = {
	name = "Music",
}

--TODO: Move process looping mechanism here.
function music:init()
	process:registerCallback(self,"command", 3,self.command)
	process:registerCallback(self,"music_play", 5,self.musicbutton)
	process:registerCallback(self,"music_received", 5,self.musicreceived)
end

function music:musicbutton(client, music)
	music.looping = true
end

function music:command(client, cmd,str,args)
	--if cmd == "play" then
	--end
end

function music:musicreceived(client, music)
	music.looping = true
end


return music
