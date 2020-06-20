--Moderation
local process = ...

local moderation = {}

function moderation:init()
	process:registerCallback(self,"client_join",5,self.check)
	process:registerCallback(self,"call_mod",3,self.call_mod)
	process:registerCallback(self,"command",3,self.command)
	process:registerCallback(self,"player_move",4,self.player_move)

	--process:registerCallback(self,"close", 0,self.save)

	local mute = {"emote","event_play","music_play","item_add","item_edit","item_remove"}
	for i,v in ipairs(mute) do
		process:registerCallback(self,v,5, self.mutehandle)
	end

	self:load()

	self.passwords = process:loadList(path.."config/passwords.txt")
end

function moderation:command(client, cmd,str,args)
	if (cmd == "modpass" or cmd == "login") and not client.mod then
		for i,v in ipairs(self.passwords) do
			if v == str then
				client.mod = true
				process:sendMessage(client,"Moderator status enabled.")
				self:print("["..tostring(client.id).."] logged in as a moderator.")
				return true
			end
		end
	end

	if not client.mod then return end

	if cmd == "reload" then
		self:print("Reloading the server now!")
		process.server:reload()
		return true
	end
	if cmd == "reloadbans" then
		self:print("Reloading the server bans!")
		self:load()
		return true
	end
	if cmd == "kick" then
		local id = tonumber(args[1])
		if id then
			local player = process:getPlayer(id)
			if player then
				player:close()
				process:sendMessage(client,"Kicked ["..id.."]")
				self:print(client:getIdent().."kicked player with id"..id)
			else
				process:sendMessage(client,"No player is online with ID "..id)
			end
		else
			process:sendMessage(client,"Please enter the ID of the player to kick.")
		end
		return true
	end
	if cmd == "ban" then
		local id = tonumber(args[1])
		local player = process:getPlayer(id)
		local reason = str:match("%d+ (.-)$")

		if not id then
			process:sendMessage(client,"Please enter the ID of the player to ban.")
			return true
		end
		if not player then
			process:sendMessage(client,"No player is online with ID "..id)
			return true
		end
		if not reason then
			process:sendMessage(client,"Please enter a reason for banning!")
			return true
		end

		local target = player.ip
		--[[if player.hardwareid and player.software == "AO2" then
			target = player.hardwareid
		end]]

		self.banned[target] = {os.time(),tostring(client.name),tostring(player.name),-1,reason}
		player:close()

		process:sendMessage(client,"Banned target: "..tostring(target))
		self:print(client:getIdent().." banned player with target "..tostring(target))

		self:save()

		return true
	end
	if cmd == "unban" then
		local ip = args[1]
		if self.banned[ip] then
			self.banned[ip]=nil
			process:sendMessage(client,"Unbanned "..ip.."!")
		else
			process:sendMessage(client,"Could not find ban with that target!")
		end
		return true
	end
	if cmd == "move" then
		local rooms = process.modules["rooms"]
		local room = rooms:getRoom(tonumber(args[2]) or args[2])
		local id = tonumber(args[1])
		if id and room then
			local player = process:getPlayer(id)
			if player then
				rooms:moveto(player,room,true)
				process:sendMessage(client,"Moved ["..id.."] to "..tostring(room.name))
			else
				process:sendMessage(client,"No player is online with ID "..id)
			end
		else
			process:sendMessage(client,"Please enter the ID of the player and room you want to move them to.")
		end
		return true
	end
	if cmd == "trap" then
		local rooms = process.modules["rooms"]
		local room = rooms:getRoom(tonumber(args[2]) or args[2])
		local id = tonumber(args[1])
		local player = process:getPlayer(id)
		if player then
			if room then
				rooms:moveto(player,room,true)
				player.trapped = true
				process:sendMessage(client,"Trapped ["..id.."] in "..tostring(room.name))
			else
				player.trapped = true
				process:sendMessage(client,"Trapped ["..id.."]")
			end
		else
			process:sendMessage(client,"No player is online with ID "..tostring(id))
		end
		return true
	end
	if cmd == "untrap" then
		local id = tonumber(args[1])
		local player = process:getPlayer(id)
		if player then
			if player.trapped then
				player.trapped = false
				process:sendMessage(client,"Untrapped ["..id.."]")
			else
				process:sendMessage(client,"["..id.."] is already untrapped!")
			end
		else
			process:sendMessage(client,"No player is online with ID "..tostring(id))
		end
		return true
	end
	if cmd == "mute" then
		local id = tonumber(args[1])
		local player = process:getPlayer(id)
		if player then
			if not player.muted then
				player.muted = true
				process:sendMessage(client,"Muted ["..id.."]")
			else
				process:sendMessage(client,"["..id.."] is already muted!")
			end
		else
			process:sendMessage(client,"No player is online with ID "..tostring(id))
		end
		return true
	end
	if cmd == "unmute" then
		local id = tonumber(args[1])
		local player = process:getPlayer(id)
		if player then
			if player.muted then
				player.muted = false
				process:sendMessage(client,"Unmuted ["..id.."]")
			else
				process:sendMessage(client,"["..id.."] is already unmuted!")
			end
		else
			process:sendMessage(client,"No player is online with ID "..tostring(id))
		end
		return true
	end
	if cmd == "unmodme" then
		client.mod = false
		process:sendMessage(client,"Moderator status disabled.")
		return true
	end

	if cmd == "load" then
		local modules = args
		if #modules == 0 then
			modules = process:loadList(path.."config/modules.txt")
		end

		for i,name in ipairs(modules) do
			process:removeModule(name)
			local suc, err = process:loadModule(name)
			if not suc then
				process:sendMessage(client, "👎 Error with "..name..": "..err)
			end
		end
		for i,name in ipairs(modules) do
			local module = process.modules[name]
			if module then
				if type(module.init) == "function" then
					local suc, err = pcall(module.init,module,process)
					if suc then
						process:sendMessage(client,"👍 '"..name.."' loaded!")
					else
						process:sendMessage(client,"👎 Error initializing '"..name.."': "..err.."")
					end
				end
			end
		end

		self:print("A mod loaded modules: "..str)
		return true
	end
end

function moderation:check(client)
	for k,v in pairs(self.banned) do
		if k == client.ip then
			self:print("Attempt to connect by '"..tostring(v[3]).."' "..tostring(client.ip))
			return true
		end
	end
end

function moderation:call_mod(client,call)
	local msg = "["..client.id.."] called for a mod! Reason: "
	local reason = call.reason or "N/A"

	self:notify(msg..reason)
	process:sendMessage(client, msg..reason)
end

function moderation:player_move(client,targetroom)
	if client.trapped then
		process:sendMessage(client,"Trapped!")
		return true
	end
end
function moderation:mutehandle(client)
	if client.muted then return true end
end


function moderation:notify(msg)
	for player in process:eachPlayer() do
		if player.mod then
			process:sendMessage(player,msg)
		end
	end
end

function moderation:load()
	self.banned = {}

	local t = process:loadList(path.."data/bans.txt")
	for i,v in ipairs(t) do
		local target = v:match("^(.-) ; ")or""
		local timebanned = tonumber(v:match(" ; (.-) ; ")or"") or -1
		local moderator = v:match(" ; .- ; (.-) ; ") or "N/A"
		local bannedname = v:match(" ; .- ; .- ; (.-) ; ") or "N/A"
		local bannedfor = tonumber(v:match(" ; .- ; .- ; .- ; (.-) ; ")or"") or -1
		local reason = v:match(" ; ([^;]-)$")or"N/A"

		self.banned[target] = {timebanned,moderator,bannedname,bannedfor,reason}
		--[[self:print("Loaded ban: "
			..tostring(target).."\t"
			..tostring(timebanned).."\t"
			..tostring(moderator).."\t"
			..tostring(bannedname).."\t"
			..tostring(bannedfor).."\t"
			..tostring(reason).."\t")]]
	end
	self:print("Loaded "..#self.banned.." bans.")
end

function moderation:save()
	local t = {}
	for ip, dat in pairs(self.banned) do
		table.insert(t,ip.." ; "..table.concat(dat," ; "))
	end
	process:saveList(t,path.."data/bans.txt")
end

return moderation
