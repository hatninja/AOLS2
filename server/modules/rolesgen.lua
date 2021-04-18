local process = ...
local rolesgen = {
	help = {
		{"rolesgen","",""},
		{"rolesadd","",""},
		{"rolesgive","",""},
	},
	gens = {

	},
}

function rolesgen:init(process)
	process:registerCallback(self,"command",1,self.command)
end

function rolesgen:command(client, cmd,str,args)
	if cmd == "rolesgen" then
		local gen = {
			mode = "public",
			roles = {},
			users = {},
			picked = {},
			gm=client,
		}
		if args[1] == "GM" then
			gen.mode = "GM"
		elseif args[1] == "private" then
			gen.mode = "private"
		end

		self.gens[client] = gen

		local msg = gen.gm:getIdent().." started a "..tostring(gen.mode).." role deck!"
		process:sendMessage(client.room or process,msg)
		self:print(msg)
		return true
	end

	--TODO: List through roles
	if cmd == "rolesadd" then
		if self.gens[client] then
			local gen = self.gens[client]
			gen.roles = args or {}
			process:sendMessage(client,"Roles: "..tostring(str))
		else
			process:sendMessage(client,"Can't add roles without a role deck!")
		end
		return true
	end

	if cmd == "rolesinvite" then
		if self.gens[client] then
			local gen = self.gens[client]
			gen.users = {}
			if args then
				for i,v in pairs(args) do
					local id = tonumber(v)
					if id then
						table.insert(gen.users,id)
					end
				end
				process:sendMessage(client,"Users Invited: "..table.concat(gen.users,", "))
			end
		else
			process:sendMessage(client,"Can't invite users without a role deck!")
		end
		return true
	end

	if cmd == "rolesgive" then
		if self.gens[client] then
			local gen = self.gens[client]

			local report = false
			local tolist = client.room

			if gen.mode == "GM" then
				report = true
				tolist = client
			elseif gen.mode == "private" then
				report = true
				tolist = false
			end

			--Shuffle user list to randomize giving.
			local count = #gen.users
			while count > 1 do
				local rand = math.random(1,count)
				gen.users[rand], gen.users[count] = gen.users[count], gen.users[rand]
				count=count-1
			end

			--Give roles
			for i=#gen.users,1,-1 do
				local role
				if #gen.roles > 0 then
					local rand = math.random(1,#gen.roles)
					role = gen.roles[rand]
					table.remove(gen.roles,rand)
				end

				gen.picked[gen.users[i]] = role or "None"

				gen.users[i] = nil
			end

			if report then
				for userid,role in pairs(gen.picked) do
					local user = process:getPlayer(userid)
					if user then
						process:sendMessage(user,"You got the "..role.." role!")
					end
				end
			end
			if tolist then
				local msg = "~Roles Given:~"
				for userid,role in pairs(gen.picked) do
					local user = process:getPlayer(userid)
					msg = msg .. "\n".. (user and user:getIdent() or userid) .. " - " .. role
				end
				process:sendMessage(tolist,msg)
			end

			self.gens[client] = nil
		else
			process:sendMessage(client,"Can't give roles without a role deck!")
		end
		return true
	end
end

return rolesgen
