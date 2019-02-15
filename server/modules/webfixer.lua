--Webfixer, makes things nicer for webAO users.
local process = ...

local webfixer = {}

function webfixer:init()
	process:registerCallback(self,"bg_received",1,self.bg)
	process:registerCallback(self,"emote_received",1,self.emote)
	process:registerCallback(self,"music_received",1,self.music)

	self.characters = process:loadList(path.."config/webfix/characters.txt")
	for i,char in ipairs(self.characters) do
		local s, e = char:find(" > ")
		self.characters[i] = {s and char:sub(1,s-1) or char, e and char:sub(e+1,-1)}
	end
	self.backgrounds = process:loadList(path.."config/webfix/backgrounds.txt")
	for i,bg in ipairs(self.backgrounds) do
		local s, e = bg:find(" > ")
		self.backgrounds[i] = {s and bg:sub(1,s-1) or bg, e and bg:sub(e+1,-1)}
	end
	self.music = process:loadList(path.."config/webfix/music.txt")
	for i,music in ipairs(self.music) do
		local s, e = music:find(" > ")
		self.music[i] = {s and music:sub(1,s-1) or music, e and music:sub(e+1,-1)}
	end
end

function webfixer:emote(sender, receiver, emote)
	if receiver.software ~= "webAO" then return end
end

function webfixer:music(sender, receiver, music)
	if receiver.software ~= "webAO" then return end
	local track = music.track:gsub("%.%w%w%w$","")
	for i,v in pairs(self.music) do
		if v[2] == track then
			music.track = v[1]
			return
		end
	end
end

function webfixer:bg(receiver, bg)
	if receiver.software ~= "webAO" then return end
	for i,v in pairs(self.backgrounds) do
		if v[2] == bg.bg then
			bg.bg = v[1]
			return
		end
	end
end

return webfixer