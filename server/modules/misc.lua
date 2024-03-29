local process = ...
local misc = {
	help = {
		{"coinflip","","Flips a coin."},
		{"diceroll","[sides]","Rolls an N-sided die."},
		{"timer","[time]","Starts and stops a timer."},
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
	if cmd == "coinflip" or cmd == "coin" then
		local result = "Heads"
		local rand = math.random(1,2)
		if rand == 2 then result = "Tails" end

		local msg = client:getIdent().." flipped a coin and got "..result.."!"
		process:sendMessage(client.room or process,msg)
		self:print(msg)
		return true
	end
	if cmd == "diceroll" or cmd == "roll" then
		local low = tonumber(args[1]) or 20
		local high = tonumber(args[2])

		local result
		local msg

		if not high then
			result = math.random(1,math.max(low,1))
			msg = client:getIdent().." rolled a "..low.."-sided die and got "..result.."!"
		else
			result = math.random(low,math.max(high,low))
			msg = client:getIdent().." rolled for a range of "..low.."-"..high.." and got "..result.."!"
		end

		process:sendMessage(client.room or process,msg)
		self:print(msg)
		return true
	end
	if cmd == "timer" then
		local time = tonumber(args[1])
		if time then
			local msg = client:getIdent().." started a timer for "..(time).." minutes!"
			process:sendMessage(client.room or process,msg)

			self.time[client] = time*60
		else
			if not self.time[client] then
				local msg = client:getIdent().." started timing!"
				process:sendMessage(client.room or process,msg)

				self.time[client] = -1
			else
				local msg = client:getIdent().." stopped timing and got "..(math.floor((self.time[client]+1)/60*100)/100).." minutes."
				process:sendMessage(client.room or process,msg)

				self.time[client] = nil
			end
		end
		return true
	end
	if cmd == "server" then
		local msg = tostring(process.server.software)
		msg = msg .. " server version "
		msg = msg .. tostring(process.server.version)
		msg = msg .. "\nMemory: " ..(collectgarbage("count")/1024) .. "MiB"
		msg = msg .. "\nAlive: " ..(process.time/60/60) .. " hours"
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
