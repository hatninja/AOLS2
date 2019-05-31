--Handles character selecting, and related functions.
local process = ...

local bghelper = {
	help = {
		{"bg","(name)","Changes the room's background."},
		{"bglist","","The list of available backgrounds."},
		{"localbg","(name)","Changes your background locally."},
		{"bd","","Shorthand background command for backdrops."},
		{"bdlist","","The list of available backdrops."},
		{"cr","","Shorthand background command for courtrooms."},
		{"crlist","","The list of available courtroom bgs."},
	}
}

function bghelper:init()
	process:registerCallback(self,"command",3,self.command)
	process:registerCallback(self,"emote",1,self.emote)

	self.backdrops = process:loadList(path.."config/backdrops.txt")
	self.courts = process:loadList(path.."config/courts.txt")

	self.backgrounds = {}
	for i,v in pairs(self.backdrops) do
		table.insert(self.backgrounds,(config.backdropdir or "")..v)
	end
	for i,v in pairs(self.courts) do
		table.insert(self.backgrounds,(config.courtdir or "")..v)
	end
end

function bghelper:command(client, cmd,str,args)
	if cmd == "bg" then
		local backgrounds = self.backgrounds
		for i,bg in ipairs(backgrounds) do
			local name = bg
			if string.lower(name) == string.lower(str) then
				process:sendMessage(client.room or process,"["..client.id.."] changed bg to '"..name.."'")
				if client.room then
					client.room.bg = name
					for i,v in pairs(client.room.players) do
						v:send("BG",{bg = name})
					end 
				end
				return true
			end
		end
		process:sendMessage(client,"'"..str.."' isn't available!")
		return true
	end
	if cmd == "bglist" then
		local list = ""
		local backgrounds = self.backgrounds

		list = list .. tostring(#backgrounds).." backgrounds total.\n"

		for i,bg in ipairs(backgrounds) do
			list = list .. bg .. ", "
		end
		list = list:sub(1, -3)
		process:sendMessage(client,list)
		return true
	end
	if cmd == "localbg" then
		local name = str
		process:sendMessage(client,"Changed background locally to '"..name.."'")
		client:send("BG",{bg = name})
		return true
	end
	if cmd == "bd" then
		local backgrounds = self.backdrops
		for i,bg in ipairs(backgrounds) do
			local name = bg
			if string.lower(name) == string.lower(str) then
				process:sendMessage(client.room or process,"["..client.id.."] changed the background to backdrop '"..name.."'")
				if client.room then
					client.room.bg = name
					for i,v in pairs(client.room.players) do
						v:send("BG",{bg = (config.backdropdir or "")..name})
					end 
				end
				return true
			end
		end
		process:sendMessage(client,"Backdrop '"..str.."' isn't available!")
		return true
	end
	if cmd == "bdlist" then
		local list = ""
		local backgrounds = self.backdrops

		list = list .. tostring(#backgrounds).." backgrounds total.\n"

		for i,bg in ipairs(backgrounds) do
			list = list .. bg .. ", "
		end
		list = list:sub(1, -3)
		process:sendMessage(client,list)
		return true
	end
	if cmd == "cr" then
		local backgrounds = self.courts
		for i,bg in ipairs(backgrounds) do
			local name = bg
			if string.lower(name) == string.lower(str) then
				process:sendMessage(client.room or process,"["..client.id.."] changed the background to court '"..name.."'")
				if client.room then
					client.room.bg = name
					for i,v in pairs(client.room.players) do
						v:send("BG",{bg = (config.courtdir or "")..name})
					end 
				end
				return true
			end
		end
		process:sendMessage(client,"Court '"..str.."' isn't available!")
		return true
	end
	if cmd == "crlist" then
		local list = ""
		local backgrounds = self.courts

		list = list .. tostring(#backgrounds).." courts total.\n"

		for i,bg in ipairs(backgrounds) do
			list = list .. bg .. ", "
		end
		list = list:sub(1, -3)
		process:sendMessage(client,list)
		return true
	end
end

function bghelper:emote(sender, emote)
	if sender.room and self:isBackdrop(sender.room.bg) then
		if emote.side == SIDE_JUD
		or emote.side == SIDE_JUR
		or emote.side == SIDE_SEA then
			emote.side = SIDE_WIT
		end
		if emote.side == SIDE_HLD then
			emote.side = SIDE_DEF
		end
		if emote.side == SIDE_HLP then
			emote.side = SIDE_PRO
		end
	end
end

function bghelper:isBackdrop(bg)
	if not bg then return end
	for i,v in pairs(self.backdrops) do
		if string.lower(bg) == string.lower((config.backdropdir or "")..v) then
			return true
		end
	end
end

return bghelper