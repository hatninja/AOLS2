--Stenofriend. All about making messages look nice.
local process = ...

local stenofriend = {}

function stenofriend:init()
	process:registerCallback(self,"emote_received",1,self.handle)
	process:registerCallback(self,"music_received",1,self.music)
	process:registerCallback(self,"emote",3,self.autocolor)
end

function stenofriend:handle(sender, receiver, emote)
	local interjection
	if emote.interjection == 1 then
		interjection = "Hold it!"
	elseif emote.interjection == 2 then
		interjection = "Objection!"
	elseif emote.interjection == 3 then
		interjection = "Take That!"
	elseif emote.interjection == 4 then
		interjection = "shouted!"
	end
	if interjection then
		receiver:send("IC",{
			dialogue=interjection,
			character=emote.character,
			name=emote.name})
	end
	
	local message = emote.dialogue
	local fixed = self:fix(message)
	--The AO2 client only clears text box when message content is exactly the same.
	emote.dialogue = (sender==receiver) and message or fixed
end

function stenofriend:music(sender, receiver, music)
	music.character = -1
end

function stenofriend:fix(text) --Taken from my custom client. Fixes all common errors.
	local t = text
	:gsub("^%s*(%l)",string.upper)
	:gsub("(%S*)%s*$","%1")
	:gsub("([?!,.;:])%s*(%l)",function(p,l) return p.." "..string.upper(l) end)
	:gsub("(%l)$","%1.")
	:gsub("%si%s"," I ")
	:gsub("^%s*(%([^%)]*)$","%1%)")
	:gsub("^%s*(%[[^%]]*)$","%1%]")
	:gsub("^%s*(%(%([^%)]*)%)?$","%1%)%)")

	if t:find("^%s*$") then t = " " end

	return t
end

function stenofriend:autocolor(client, emote)
	local msg = emote.dialogue

	--TODO: 2.6.0 exists now. Revamp may be nessecary.
	--Color message
	--[[local tc = emote.text_color
	if tc == COLOR_WHITE and client.software ~= "2.6.0" then --Change only if player hasn't.
		if msg:find("^%([^%(].-[^%)]%)$") then  --(Thinking brackets = blue)!
			emote.text_color = COLOR_BLUE
		end
		if msg:find("^%*.-%*$") then --*Is Orange*
			emote.text_color = COLOR_ORANGE
		end 
		if msg:find("^%s-[%=%-%~][%=%-%~]+.-[%=%-%~][%=%-%~]+%s-$") then --Start and end cards--
			emote.text_color = COLOR_ORANGE
			emote.text_centered = true
		end
	end]]
end

return stenofriend