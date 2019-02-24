local process = ...
local misc = {
	help = {
		{"coinflip","","Flips a coin."},
		{"diceroll","(sides)","Rolls an N-sided die."},
		{"timer","(time)","Starts and stops a timer."}
	}
}

function misc:init(process)
	process:registerCallback(self,"command",3,self.command)

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
		
		local msg = "["..client.id.."] flipped a coin and got "..result.."!"
		process:sendMessage(client.room or process,msg)
		self:print(msg)
		return true
	end
	if cmd == "diceroll" then
		local range = tonumber(args[2]) or 6
		local result = math.random(1,math.max(range,1))
		
		local msg = "["..client.id.."] rolled a "..range.."-sided die and got "..result.."!"
		process:sendMessage(client.room or process,msg)
		self:print(msg)
		return true
	end
	if cmd == "timer" then
		local time = tonumber(args[1])
		if time then
			self.time[client] = time
			local msg = "["..client.id.."]  started a timer for "..time.." seconds!"
			process:sendMessage(client.room or process,msg)
		else
			if not self.time[client] then
				local msg = "["..client.id.."] started timing!"
				self.time[client] = -1
				process:sendMessage(client.room or process,msg)
			else
				local msg = "["..client.id.."] stopped timing at "..math.abs(self.time[client]+1).." seconds."
				self.time[client] = nil
				process:sendMessage(client.room or process,msg)
			end
		end
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