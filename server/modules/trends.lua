--Tracks and plots server actions and data over time.
local process = ...

local SAVE_RATE = 60*60
local SAVE_DIR = path.."data/"

local trends = {}

function trends:init()
	process:registerCallback(self,"update",0,self.update)

	process:registerCallback(self,"emote",0,function(self,client,emote)
		local message = emote.dialogue or ""
		self:plot("EL",#message,client.room)
		self:plot("EC",emote.character,client.room)
		self:plot("EN",client.showname,client.room)
	end)
	process:registerCallback(self,"ooc",0,function(self,client,emote)
		local message = emote.message or ""
		self:plot("OL",#message,client.room)
		self:plot("ON",client.name,client.room)
	end)
	process:registerCallback(self,"player_move",0,function(self, client, room)
		self:plot("RC",room and room.count+1,room)
		self:plot("RC",client.room and client.room.count-1,client.room)
	end)
	process:registerCallback(self,"player_join",0,function(self, client, room)
		self:plot("PC",process.playercount)
	end)
	process:registerCallback(self,"player_leave",0,function(self, client, room)
		self:plot("PC",process.playercount-1)
	end)

	self.appendqueue = ""
	self.timer = 0

	self.rooms = {}

	process:registerCallback(self,"rooms_reload",0,function(client, room)
		local parent = process.modules["rooms"]
		for k,v in pairs(parent.rooms) do
			self.rooms[v] = k
		end
	end)

end

function trends:plot(kind,datum,room)
	local append = ""

	append=append.. tostring(kind) .. "¤"
	append=append.. tostring(os.time()) .. "¤"
	append=append.. tostring(datum) .. "¤"
	append=append.. tostring(room and self.rooms[room]) .. "¤\n"

	self.appendqueue = self.appendqueue .. append
end

function trends:update()
	self.timer = self.timer + config.rate
	if self.timer > SAVE_RATE then
		self.timer = 0

		self:append()
		self:print("Appended trend data.")
	end
end

function trends:append()
	if #self.appendqueue == 0 then return end

	local file,err = io.open(SAVE_DIR.."trends.txt","a")
	assert(file,err)
	file:write(self.appendqueue)
	file:close()

	self.appendqueue = ""
end

return trends
