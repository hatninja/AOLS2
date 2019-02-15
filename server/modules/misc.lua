local process = ...
local misc = {
	help = {
		{"coinflip","","Flips a coin."},
		{"diceroll","(Sides)","Rolls an N-sided die."}
	}
}

function misc:init(process)
	process:registerCallback(self,"command",3,self.command)
end

function misc:command(client, cmd,str,args)
	if cmd == "coinflip" then
		local result = "Heads"
		local rand = math.random(1,2)
		if rand == 2 then result = "Tails" end
		
		local msg = tostring(client.name).." flipped a coin and got "..result.."!"
		process:sendMessage(client.room,msg)
		self:print(msg)
		return true
	end
	if cmd == "diceroll" then
		local range = tonumber(args[2]) or 6
		local result = math.random(1,math.max(range,1))
		
		local msg = tostring(client.name).." rolled a "..range.."-sided die and got "..result.."!"
		process:sendMessage(client.room,msg)
		self:print(msg)
		return true
	end
end

return misc