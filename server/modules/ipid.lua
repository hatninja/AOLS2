--ipid functionality.
local process = ...

local ipid = {}

function ipid:init()
	process:registerCallback(self, "client_join",6, self.find)
	process:registerCallback(self, "player_join",6, self.assign)

	self:load()
end

function ipid:find(client)
	local ip = tostring(client.ip)
	local ipid = self.assigned[ip]
	if ipid then return end
	client.ipid = ipid
end

function ipid:assign(client)
	local ip = tostring(client.ip)
	if not self.assigned[ip] then
		self.last = self.last + 1
		self.assigned[ip] = self.last
	end

	client.ipid = self.last

	self:save()
end

function ipid:getIP(id)
	for k,v in pairs(self.assigned) do
		if v == id then
			return k
		end
	end
end
function ipid:getID(ip)
	return self.assigned[ip]
end

function ipid:load()
	self.assigned = {}
	self.last = 0

	local list = process:loadList(path.."data/ipids.txt")
	for i,v in ipairs(list) do
		local ip = v:match("^(.-);")
		local ip = tonumber(v:match(";(.-)$"))
		if ip and id then
			self.assigned[ip] = id

			self.last = math.max(self.last,id)
		end
	end
	self:print("Loaded "..self.last.." ipids from file.")
end

function ipid:save()
	local t = {}
	for ip, id in pairs(self.assigned) do
		table.insert(t,ip..";"..id)
	end
	process:saveList(t,path.."data/ipids.txt")
end

return ipid
