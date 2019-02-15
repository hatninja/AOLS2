--Moderation
local process = ...

local moderation = {}

function moderation:init()
	process:registerCallback(self,"client_join",5,self.join)
	process:registerCallback(self,"call_mod",3,self.call_mod)
	process:registerCallback(self,"command",3,self.command)


	self.passwords = process:loadList(path.."config/passwords.txt")

	self.blocked = {}
end

function moderation:command(client, cmd,str,args)
	if cmd == "modpass" then
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
				process:sendMessage(client,"Kicked player "..id)
				self:print("Mod["..client.id.."] kicked player with id"..id)
			else
				process:sendMessage(client,"No player is online with ID "..id)
			end
		else
			process:sendMessage(client,"Please enter the ID of the player to kick.")
		end
		return true
	end
	if cmd == "block" then
		local id = tonumber(args[1])
		if id then
			local player = process:getPlayer(id)
			if player then
				self.blocked[player.ip] = true
				player.socket:close()
				process:sendMessage(client,"Blocked ip: "..tostring(player.ip))
				self:print("Mod["..client.id.."] blocked player with ip "..tostring(player.ip))
			else
				process:sendMessage(client,"No player is online with ID "..id)
			end
		else
			process:sendMessage(client,"Please enter the ID of the player to kick.")
		end
		return true
	end
end

function moderation:join(client)
	if self.blocked[client.ip] then
		return true
	end
end

function moderation:call_mod(client,call)
	local msg = "["..client.id.."] called for a mod! Reason: "
	local reason = call.reason or "N/A"

	self:notify(msg..reason)
	process:sendMessage(client, msg..reason)
end

function moderation:notify(msg)
	for player in process:eachPlayer() do
		if player.mod then
			process:sendMessage(player,msg)
		end
	end
end

return moderation