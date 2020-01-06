--Room: Stores room information. Mainly used for the 'room' module.

local Room = {}
Room.__index=Room

function Room:new(...)
	local t = {}
	self.init(t,...)
	return setmetatable(t,self)
end

function Room:init(room, id)
	for k,v in pairs(room) do --Room table loaded from config.
		self[k] = v
	end

	self.name = room.name
	self.kind = room.kind or "rp"
	self.music = room.music or "No Music"
	self.bg = room.bg or "gs4"
	self.evidence = room.evidence or {}

	self.players = {}
	self.count = 0
end

return Room
