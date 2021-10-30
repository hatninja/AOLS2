--Chatbuffer. Handles buffering of chat events.
local process = ...


local chatbuffer = {
	help = {
		{"buffer","","Buffer mode. Delays WT/CE and music until a message is sent."}
	}
}

function chatbuffer:init()
	process:registerCallback(self,"emote",5.1,self.handle)
	process:registerCallback(self,"music_play",2,self.music) --Rooms.lua:36
	process:registerCallback(self,"event_play",1,self.event)

	process:registerCallback(self,"command", 3,self.command)

	self.eventbuffer = {}
	self.musicbuffer = {}
end

function chatbuffer:command(client, cmd,str,args)
	if cmd == "buffer" then
		client.buffermode = not client.buffermode

		local msg = "Buffer mode on."
		if not client.buffermode then msg = "Buffer mode off." end

		process:sendMessage(client,msg)
		return true
	end
end


function chatbuffer:handle(client, emote)
	local room = client.room or "nil"

	if self.musicbuffer[room] then
		local music = self.musicbuffer[room]
		room.music = music
		for player in process:eachPlayer() do
			if room == player.room then
				process:sendMusic(player,music,-1,nil,1)
			end
		end

		self.musicbuffer[room] = nil
	end
	if self.eventbuffer[room] then
		for player in process:eachPlayer() do
			if room == player.room then
				player:send("EVENT",self.eventbuffer[room])
			end
		end

		self.eventbuffer[room] = nil
	end
end

function chatbuffer:music(client, music)
	if not client.buffermode then return end
	local room = client.room or "nil"

	if music and client.character ~= -1 then
		if music ~= self.musicbuffer[room] then
			self.musicbuffer[room] = music
			process:sendMessage(room,client:getIdent().." buffered "..tostring(type(music)=="table" and music.track or music))
		end
		return true
	end
end

function chatbuffer:event(client, event)
	if not client.buffermode then return end
	local room = client.room or "nil"

	if (event.event == "witness_testimony"
	or event.event == "cross_examination"
	or event.event == "verdict_notguilty"
	or event.event == "verdict_guilty"
	) then
		if event ~= self.eventbuffer[room] then
			process:sendMessage(room,client:getIdent().." buffered "..tostring(event.event))
			self.eventbuffer[room] = event
		end
		return true
	end
end

return chatbuffer
