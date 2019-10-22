local process = ...
local misc = {
	help = {
		{"coinflip","","Flips a coin."},
		{"diceroll","(sides)","Rolls an N-sided die."},
		{"timer","(time)","Starts and stops a timer."},
		{"server","","Returns information about the server."}
	}
}

function misc:init(process)
	process:registerCallback(self,"command",1,self.command)

	process:registerCallback(self,"list_characters",3,self.shuffle)
	process:registerCallback(self,"list_music",3,self.shuffle_music)

	self.time = {}
	process:registerCallback(self,"player_leave",3,self.leave)
	process:registerCallback(self,"player_update",3,self.timerupdate)
end

function misc:command(client, cmd,str,args)
	if cmd == "coinflip" then
		local result = "Heads"
		local rand = math.random(1,2)
		if rand == 2 then result = "Tails" end

		local msg = client:getIdent().." flipped a coin and got "..result.."!"
		process:sendMessage(client.room or process,msg)
		self:print(msg)
		return true
	end
	if cmd == "diceroll" then
		local range = tonumber(args[1]) or 6
		local result = math.random(1,math.max(range,1))

		local msg = client:getIdent().." rolled a "..range.."-sided die and got "..result.."!"
		process:sendMessage(client.room or process,msg)
		self:print(msg)
		return true
	end
	if cmd == "timer" then
		local time = tonumber(args[1])
		if time then
			time = time*60
			self.time[client] = time
			local msg = client:getIdent().." started a timer for "..(time/60).." minutes!"
			process:sendMessage(client.room or process,msg)
		else
			if not self.time[client] then
				local msg = client:getIdent().." started timing!"
				self.time[client] = -1
				process:sendMessage(client.room or process,msg)
			else
				local msg = client:getIdent().." stopped timing and got "..(math.floor(math.abs(self.time[client]+1)/60*100)/100).." minutes."
				self.time[client] = nil
				process:sendMessage(client.room or process,msg)
			end
		end
		return true
	end
	if cmd == "server" then
		local msg = tostring(process.server.software)
		msg = msg .. " server version "
		msg = msg .. tostring(process.server.version)
		if client.mod then
			msg = msg .. (collectgarbage("count")/1024) .. "MiB"
		end
		process:sendMessage(client,msg)
		return true
	end
	--Config print
	if config[cmd] then
		process:sendMessage(client, tostring(config[cmd]))
		return true
	end
end

function misc:shuffle(client, list)
	if config.shuffle then
		local count = #list
		while count > 1 do
			local rand = math.random(1,count)
			list[rand], list[count] = list[count], list[rand]
			count=count-1
		end
	end
end

local Music = dofile(path.."server/classes/music.lua")

function misc:shuffle_music(client, list)
	if config.shuffle then
		local count = #list
		while count > 1 do
			local rand = math.random(1,count)
			list[rand], list[count] = list[count], list[rand]
			count=count-1
		end

		table.insert(list,1,Music:new("-"))
		table.insert(list,2,Music:new("-.mp3"))
	end
end

function misc:leave(client)
	self.time[client] = nil
end
function misc:timerupdate(client)
	if self.time[client] then
		self.time[client] = self.time[client] - config.rate
		if self.time[client] > 0 and self.time[client] < 1 then
			local msg = "["..client.id.."]'s timer has finished!"
			process:sendMessage(client.room or process,msg)
			self.time[client] = nil
		end
	end
end

return misc
