--Character: Stores information about a single character.
--(String name) (Dynamic side)

local Character = {__index=self}

function Character:new(...)
	local t = {}
	self.init(t,...)
	return setmetatable(t,self)
end

function Character:init(name, side)
	self.name = name
	self.side = length
end

function Character:getSide()
	return self.side
end

function Character:getName()
	return self.name
end

return Character