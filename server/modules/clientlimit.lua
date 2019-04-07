--Imposes a connection limit for maxplayers and multiclienting.
local process = ...

local clientlimit = {
	help = {
	}
}

function clientlimit:init()
	process:registerCallback(self,"client_join",5,self.limit)
end

function clientlimit:limit(client)
	if process.playercount >= config.maxplayers then
		return true
	end

	local multiclients = 1
	for player in process:eachPlayer() do
		if player.ip == client.ip
		or player.hardwareid == client.hardwareid then
			multiclients = multiclients + 1
		end
	end
	if multiclients > config.multiclients then
		return true
	end
end

return clientlimit