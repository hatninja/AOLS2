--Handles character selecting, and related functions.
--Implements events 'room_bg' and 'player_bg'
local process = ...

local bghelper = {
	help = {
		{"bg","(name)","Changes the room's background."},
		{"bglist","","The list of available backgrounds."},
		{"randombg","","Changes to a random background."},
		{"localbg","(name)","Changes your background locally."},
		{"bd","","Shortcut bg command for backdrops."},
		{"bdlist","","The list of available backdrops."},
		{"randombd","","Changes to a random backdrop."},
		{"court","","Shortcut bg command for courtrooms."},
		{"courtlist","","The list of available courtrooms."},
		{"randomcourt","","Changes to a random courtroom background."},
	}
}

function bghelper:init()
	process:registerEvent("room_bg")
	process:registerEvent("player_bg")

	process:registerCallback(self,"room_bg",1,self.room_bg)
	process:registerCallback(self,"player_bg",1,self["player_bg"])

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
	if cmd == "background" or cmd == "bg" then
		local backgrounds = self.backgrounds
		for i,bg in ipairs(backgrounds) do
			local name = bg
			if string.lower(name) == string.lower(str) then
				if process:event("room_bg",client, client.room or process, name) then
					process:sendMessage(client.room or process,client:getIdent().." changed the background to '"..name.."'")
				end
				return true
			end
		end
		process:sendMessage(client,"'"..str.."' isn't available!")
		return true
	end
	if cmd == "backgrounds" or cmd == "bglist" then
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
	if cmd == "randombg" then
		local backgrounds = self.backgrounds
		local rand = math.random(1,#backgrounds)
		local name = backgrounds[rand]
		if process:event("room_bg", client, client.room or process, name) then
			process:sendMessage(client.room or process,client:getIdent().." changed the background to '"..name.."' by random.")
		end
		return true
	end
	if cmd == "localbg" then
		local name = str
		process:sendMessage(client,"Changed background locally to '"..name.."'")
		process:event("player_bg",client,name,true)
		return true
	end
	if cmd == "backdrop" or cmd == "bd" then
		local backgrounds = self.backdrops
		for i,bg in ipairs(backgrounds) do
			local name = bg
			if string.lower(name) == string.lower(str) then
				if process:event("room_bg",client, client.room or process, (config.backdropdir or "")..name) then
					process:sendMessage(client.room or process,client:getIdent().." changed the background to backdrop '"..name.."'")
				end
				return true
			end
		end
		process:sendMessage(client,"Backdrop '"..str.."' isn't available!")
		return true
	end
	if cmd == "backdrops" or cmd == "bdlist" then
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
	if cmd == "randombd" then
		local backgrounds = self.backdrops
		local rand = math.random(1,#backgrounds)
		local name = backgrounds[rand]
		if process:event("room_bg", client, client.room or process, (config.backdropdir or "")..name) then
			process:sendMessage(client.room or process,client:getIdent().." changed the background to backdrop '"..name.."' by random.")
		end
		return true
	end
	if cmd == "court" or cmd == "cr" then
		local backgrounds = self.courts
		for i,bg in ipairs(backgrounds) do
			local name = bg
			if string.lower(name) == string.lower(str) then
				if process:event("room_bg",client, client.room or process, (config.courtdir or "")..name) then
					process:sendMessage(client.room or process,client:getIdent().." changed the background to court '"..name.."'")
				end
				return true
			end
		end
		process:sendMessage(client,"Court '"..str.."' isn't available!")
		return true
	end
	if cmd == "courts" or cmd == "crlist" then
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
	if cmd == "randomcourt" or cmd == "randomcr" then
		local backgrounds = self.courts
		local rand = math.random(1,#backgrounds)
		local name = backgrounds[rand]
		if process:event("room_bg", client, client.room or process, (config.courtdir or "")..name) then
			process:sendMessage(client.room or process,client:getIdent().." changed the background to court '"..name.."' by random.")
		end
		return true
	end
end

function bghelper:room_bg(client,room,bgname)
	room.bg = bgname
	for i,v in pairs(room.players) do
		process:sendBG(client,bgname)
	end
end
function bghelper:player_bg(client,bgname,islocal)
	client:send("BG",{bg = bgname})
end

function bghelper:emote(sender, emote)
	if sender.room and self:isBackdrop(sender.room.bg) then
		if emote.side == SIDE_JUD
		or emote.side == SIDE_JUR
		or emote.side == SIDE_SEA
		then
			 emote.side = SIDE_WIT
		end

		if emote.side == SIDE_HLD
		then
			 emote.side = SIDE_DEF
		end

		if emote.side == SIDE_HLP
		then
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
