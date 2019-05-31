--Handles spacers in the character list. Only works for AO2, for now.
local process = ...

local spacers = {
}

local Character = require(path.."server/classes/character")

function spacers:init()
	process:registerCallback(self,"list_characters",3,self.list_characters)

	self.rules = process:loadList(path.."config/spacers.txt")
	for i,str in ipairs(self.rules) do
		local s, e = str:find(", .-, ")
		self.rules[i] = {
			str:sub(1,s-1),
			str:sub(s+2,e-2),
			str:sub(e+1,-1),
		}
	end


	self.cache = {}
	for i, rule in ipairs(self.rules) do
		if not self.cache[rule[2]] then
			self.cache[rule[2]] = Character:new(rule[2])
		end
	end
end


function spacers:list_characters(client, list)
	if client and client.software ~= "AO2" then return end

	for i, rule in ipairs(self.rules) do
		if type(str) == "string" then break end

		local targets = {}
		if tonumber(rule[1]) then
			targets[1] = tonumber(rule[1])
		elseif rule[1]:find(":") then
		else
			for i2,char in ipairs(list) do
				if char:getName() == rule[1] then
					targets[#targets+1] = i2
				end
			end
		end

		local columns = 10
		local rows = 9

		for i2, tpos in ipairs(targets) do
			local char = self.cache[rule[2]]
			
			local count = tonumber(rule[3])
			if not count then --"page"
				count = math.ceil(tpos/(columns*rows))*(columns*rows) - tpos
			elseif count < 0 then
				count = (math.ceil(tpos/columns)*columns - tpos) + (math.abs(tonumber(rule[3]))-1)*columns
			end

			for r=1,count do
				table.insert(list,tpos+1,char)
			end
		end
	end
end

return spacers