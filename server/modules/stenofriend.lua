--Stenofriend. Adds steno mode.
local process = ...

local stenofriend = {
	help = {
		{"steno","","Toggles steno mode.",
			  "Steno mode makes chat log cleaner and easier to copy-paste."
			.."\n((Double brackets move to OOC))"
			.."\nMusic changes are hidden."
			.."\n*Corrections are hidden"
			.."\nCommon typing/punctuation mistakes are fixed."
		},
	}
}

function stenofriend:init()
	process:registerCallback(self,"emote_received",1,self.handle)
	process:registerCallback(self,"music_received",1,self.music)
	process:registerCallback(self,"emote",3,self.autocolor)
	process:registerCallback(self,"command",3,self.command)

	self.lastreceive = {}
end

function stenofriend:command(client, cmd,str,args)
	if cmd == "steno" then
		client.steno = not client.steno

		local msg = "Steno mode enabled."
		if not client.steno then msg = "Steno mode disabled." end

		process:sendMessage(client,msg)
		return true
	end
end

function stenofriend:handle(sender, receiver, emote)
	if receiver.steno then
		local message = emote.dialogue
		local fixed = self:fix(message)

		--((Move this to actual OOC))
		if fixed:sub(1,2) == "((" then
			process:sendMessage(receiver, message, emote.name or emote.character)
			return true
		end
		--*Correction, you can fix it in post.
		if fixed:find("^%s*%*[^%*]-$") then
			return true
		end

		local interjection
		if emote.interjection == 1 then interjection = "Hold it!"
		elseif emote.interjection == 2 then interjection = "Objection!"
		elseif emote.interjection == 3 then interjection = "Take That!"
		elseif emote.interjection == 4 then interjection = "Custom!"
		end
		if interjection then
			process:sendEmote(receiver,{
				dialogue=interjection,
				character=emote.character,
				name=emote.name
			})
		end

		--The AO2 client only clears text box when message content is exactly the same.
		emote.dialogue = (sender==receiver) and message or fixed
	end
end

function stenofriend:music(sender, receiver, music)
	if not receiver.steno then return end
	music.character = -1
end

function stenofriend:fix(text) --Taken from my custom client. Fixes all common errors.
	local t = text
	:gsub("^%s*(%l)",string.upper)
	:gsub("(%S*)%s*$","%1")
	:gsub("([?!,.;:])%s*(%l)",function(p,l) return p.." "..string.upper(l) end)
	:gsub("(%l)$","%1.")
	:gsub("%si%s"," I ")
	:gsub("^%s*(%([^%)]*)$","%1)")
	:gsub("^%s*(%[[^%]]*)$","%1]")
	:gsub("^%s*(%(%([^%)]*)%)?$","%1))")

	if t:find("^%s*$") then t = " " end

	return t
end

function stenofriend:autocolor(client, emote)
	local msg = emote.dialogue

	local tc = emote.text_color
	if tc == COLOR_WHITE then
		if msg:find("^%(.-%)$") then  --(Thinking brackets = blue)!
			emote.text_color = COLOR_BLUE
		end
		if msg:find("^%*.-%*$") then --*Is Orange*
			emote.text_color = COLOR_ORANGE
		end
		if msg:find("^%s-[%=%-%~][%=%-%~]+.-[%=%-%~][%=%-%~]+%s-$") then --Start and end cards--
			emote.text_color = COLOR_ORANGE
		end
	end
end

return stenofriend
