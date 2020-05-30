--Chatbuffer. Handles buffering of chat and events.
local process = ...

local CHAT_RATE = 0--0.06
local CHAT_DELAY = 1
local CHAT_MAX = 5

local chatbuffer = {
	help = {
		{"buffer","","Toggles buffer mode. Delays WT/CE and music until a message is sent."}
	}

}

function chatbuffer:init()
	process:registerCallback(self,"emote",5.1,self.handle)
	process:registerCallback(self,"music_play",2,self.music) --Rooms.lua:36
	process:registerCallback(self,"event_play",1,self.event)
	process:registerCallback(self,"update",3,self.update)

	process:registerCallback(self,"command", 3,self.command)

	self.emotebuffer = {}
	self.eventbuffer = {}
	self.musicbuffer = {}
end

function chatbuffer:command(client, cmd,str,args)
	if cmd == "buffer" then
		client.buffermode = not client.buffermode

		local msg = "Buffer mode enabled."
		if not client.buffermode then msg = "Buffer mode disabled." end

		process:sendMessage(client,msg)
		return true
	end
end

function chatbuffer:handle(client, emote)
	local room = client.room or "nil"

	if not emote.buffered then
		emote.buffered = true

		local message = emote.dialogue
		local delay = CHAT_DELAY+#message*CHAT_RATE

		if not self.emotebuffer[room] then
			self.emotebuffer[room] = {}
		end
		local buffer = self.emotebuffer[room]

		if emote.interjection and buffer[#buffer] then
			buffer[#buffer][2] = buffer[#buffer][2]/2
		end

		if #buffer < CHAT_MAX then
			table.insert(buffer,{emote,delay,client})
		end

		if buffer[2] then
			return true
		end
	end
	if self.musicbuffer[room] then
		for player in process:eachPlayer() do
			if room == player.room then
				player:send("MUSIC",self.musicbuffer[room])
			end
		end
		if client.room then
			client.room.music = self.musicbuffer[room].track
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

	if not music.buffered and character ~= -1 then
		music.buffered = true

		self.musicbuffer[room] = music

		return true
	end
end

function chatbuffer:event(client, event)
	if not client.buffermode then return end
	local room = client.room or "nil"

	if not event.buffered
	and ( event.event == "witness_testimony"
	or event.event == "cross_examination"
	or event.event == "verdict_notguilty"
	or event.event == "verdict_guilty"
	) then
		event.buffered = true

		self.eventbuffer[room] = event

		return true
	end
end

function chatbuffer:update()
	for room,buffer in pairs(self.emotebuffer) do
		if buffer[1] then

			buffer[1][2] = buffer[1][2] - config.rate
			if buffer[1][2] <= 0 then
				table.remove(buffer,1)

				if buffer[1] then
					process:send(buffer[1][3],"IC",buffer[1][1])
				end
			end

		end
	end
end

return chatbuffer
