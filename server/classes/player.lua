--Player, extension of client for use in process.
local Player = {}

function Player:init()

	function self:getIdent()
		local name = self.name and " "..self.name or ""
		local prefix = "["..self.id.."]"
		if self.mod then
			prefix = prefix.."[Mod]"
		end
		return prefix..name
	end

end

return Player
