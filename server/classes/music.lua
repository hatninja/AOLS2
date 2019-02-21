--Music: Stores information about a single track.
--(String name) (Number length)

local Music = {}
Music.__index=Music

function Music:new(...)
	local t = {}
	self.init(t,...)
	return setmetatable(t,self)
end

function Music:init(name, length)
	self.name = name
	self.length = length
end

function Music:getLength()
	return self.length
end

function Music:getName()
	return self.name
end

return Music