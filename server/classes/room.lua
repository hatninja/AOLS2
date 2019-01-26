--Room: Stores room information

local Room = {__index=self}

function Room:new(...)
	local t = {}
	self.init(t,...)
	return setmetatable(t,self)
end

function Room:init(room)
	self.name = room.name or k
	self.kind = room.kind or "court"
	self.music = room.music or "No Music"
	self.bg = room.bg or "gs4"
	self.hp = room.hp or room.kind ~= "lobby" and {10,10} or {0,0}
	self.evidence = room.evidence or {}

	self.players = {}
	self.count = 0
end

return Room