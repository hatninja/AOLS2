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
	music.channel = 0
end

--TODO: Queue music
function music:command(client, cmd,str,args)
	if cmd == "play" then
		local room = client.room or process
		room.music = str
		for player in process:eachPlayer() do
			if room == player.room then
				process:sendMusic(player,str,-1,nil,1)
			end
		end
		process:sendMessage(room,client:getIdent().." |> "..str)
		return true
	end
end

function music:musicreceived(client, music)
	music.looping = true
	music.channel = 0
end


return music
