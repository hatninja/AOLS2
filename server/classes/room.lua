--Room: Stores room information

local Room = {__index=self}

function Room:new(...)
	local t = {}
	self.init(t,...)
	return setmetatable(t,self)
end

function Room:init()
end

return Room