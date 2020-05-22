--Chatbuffer. Handles buffering of events.
local process = ...

local CHAT_RATE = 0.06
local CHAT_DELAY = 1
local CHAT_MAX = 10

local chatbuffer = {}

function chatbuffer:init()
	process:registerCallback(self,"emote",5,self.handle)
	process:registerCallback(self,"music_play",5,self.music)
	process:registerCallback(self,"event",5,self.music)
end

function chatbuffer:handle(client, emote)
	local message = emote.dialogue
end

function chatbuffer:music(client, music)
end

return chatbuffer
