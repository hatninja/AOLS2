--Moderation
local process = ...

local moderation = {}

function moderation:init()
	process:registerCallback(self,"client_join",5,self.join)
	process:registerCallback(self,"call_mod",3,self.call_mod)
	process:registerCallback(self,"command",3,self.command)
	process:registerCallback(self,"player_move",4,self.player_move)

	local mute = {"emote","event_play","music_play","item_add","item_edit","item_remove"}
	for i,v in ipairs(mute) do
		process:registerCallback(self,v,5, self.mutehandle)
	end

	self.passwords = process:loadList(path.."config/passwords.txt")

	self.banned = {}
end

function moderation:command(client, cmd,str,args)
	if cmd == "modpass" and not client.mod then
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
	if cmd == "kick" then
		local id = tonumber(args[1])
		if id then
			local player = process:getPlayer(id)
			if player then
				player.socket:close()
				process:sendMessage(client,"Kicked ["..id.."]")
				self:print("Mod["..client.id.."] kicked player with id"..id)
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
		local reason = args[2]
		--if not reason then process:sendMessage(client,"Please enter a reason to ban!") return end

		if id then
			local player = process:getPlayer(id)
			if player then
				self.banned[player.ip] = true
				player.socket:close()

				process:sendMessage(client,"Banned ip: "..tostring(player.ip))
				self:print("Mod["..client.id.."] banned player with ip "..tostring(player.ip))
			else
				process:sendMessage(client,"No player is online with ID "..id)
			end
		else
			process:sendMessage(client,"Please enter the ID of the player to ban.")
		end
		return true
	end
	if cmd == "unban" then
		local ip = args[1]
		if self.banned[ip] then
			self.banned[ip]=nil
			process:sendMessage(client,"Unbanned "..ip.."!")
		else
			process:sendMessage(client,"Could not find ban with that IP!")
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
				rooms:moveto(client,room,true)
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
				rooms:moveto(client,room,true)
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
end

function moderation:join(client)
	if self.banned[client.ip] then
		return true
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


return moderation