--Makes dialogue look nicer.
local fancify = {}

function fancify:init(process)
	local c=""
	process:registerCallback(self,"emote",2,function(self,client,emote)
		local msg = emote.dialogue

		--Color message
		local tc = emote.text_color
		if not (not tc or tc == COLOR_WHITE) then --Change only if player hasn't.
			if msg:find("^%([^%(].-[^%)]%)$") then  --(Thinking brackets = blue)!
				emote.text_color = COLOR_BLUE
			end
			if msg:find("^%*.-%*$") then --*Is Orange*
				emote.text_color = COLOR_ORANGE
			end 
			if msg:find("^%s-[%=%-%~][%=%-%~]+.-[%=%-%~][%=%-%~]+%s-$") then --Start and end cards--
				emote.text_color = COLOR_ORANGE
				--emote.text_centered = true
			end
		end
	end)
end
return fancify