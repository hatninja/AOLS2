local process = ...
local misc = {
	help = {
		{"coinflip","","Flips a coin."},
		{"diceroll","(sides)","Rolls an N-sided die."}
	}
}

function misc:init(process)
	process:registerCallback(self,"command",3,self.command)

	process:registerCallback(self,"list_characters",3,self.shuffle)
	process:registerCallback(self,"list_music",3,self.shuffle_music)
end

function misc:command(client, cmd,str,args)
	if cmd == "coinflip" then
		local result = "Heads"
		local rand = math.random(1,2)
		if rand == 2 then result = "Tails" end
		
		local msg = tostring(client.name).." flipped a coin and got "..result.."!"
		process:sendMessage(client.room or process,msg)
		self:print(msg)
		return true
	end
	if cmd == "diceroll" then
		local range = tonumber(args[2]) or 6
		local result = math.random(1,math.max(range,1))
		
		local msg = tostring(client.name).." rolled a "..range.."-sided die and got "..result.."!"
		process:sendMessage(client.room or process,msg)
		self:print(msg)
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

return misc