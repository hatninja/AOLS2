local process = ...

local pairing = {
	help = {
		{"userpair","[user]","Pair manually with a user.","For manual pairing to work, your target must have also set you as their pair.\nEnter no user id to disable the manual pair."},
		{"autopair","","Toggles automatic pairing.","If enabled, your emotes will pair automatically with the last autopairer's emote."},
	}
}

function pairing:init()
	self.parent = process.modules["rooms"]

	self.lastemote = {}

	process:registerCallback(self,"emote", 3,self.emote)
	process:registerCallback(self,"player_leave", 3,self.leave)
	process:registerCallback(self,"player_move", 3,self.leave)
	process:registerCallback(self,"command", 3,self.command)
end

function pairing:command(client, cmd,str,args)
	if cmd == "userpair" then
		local id = tonumber(args[1])
		local player = process:getPlayer(id)
		if player then
			client.pair = id
			process:sendMessage(client,"Player found! Setting pair.")
			if client.pair == player.id and player.pair == client.id then
				process:sendMessage(client,"Pairing connected!")
				process:sendMessage(player,"Pairing connected!")
			end
		else
			client.pair = nil
			process:sendMessage(client,"Player not found! Turning pair off.")
		end
		return true
	end
	if cmd == "autopair" then
		client.autopair = not client.autopair
		if client.autopair then
			process:sendMessage(client,"Autopair enabled.")
		else
			process:sendMessage(client,"Autopair disabled.")
		end
		return true
	end
end

function pairing:emote(client, emote)
	self.lastemote[client] = emote
	emote.time = process.time

	if client.autopair then
		local latestemote
		for player in process:eachPlayer() do
			if player ~= client then
				local otheremote = self.lastemote[player]
				if otheremote
				and player.room == client.room
				and emote.side == otheremote.side
				and player.autopair and client.autopair then
					if not latestemote or latestemote.time > otheremote.time then
						latestemote = otheremote
					end
				end
			end
		end
		if latestemote then
			emote.pair = latestemote.character
			emote.hscroll = emote.hscroll or 0
			emote.pair_emote = latestemote.emote
			emote.pair_flip = latestemote.flip
			emote.pair_hscroll = math.abs(latestemote.hscroll or 0)*(emote.hscroll > 0 and -1 or 1)
		end
	end
	if client.pair then
		local player = process:getPlayer(client.pair)
		if player then
			local otheremote = self.lastemote[player]

			if otheremote
			and client.pair == player.id
			and player.pair == client.id then
				emote.pair = otheremote.character
				emote.hscroll = emote.hscroll or 0

				emote.pair_emote = otheremote.emote
				emote.pair_hscroll = otheremote.hscroll
				emote.pair_flip = otheremote.flip
			end
		else
			client.pair = nil
			process:sendMessage(client,"Paired player not online! Turning pair off.")
		end
	end
	for player in process:eachPlayer() do
		if player ~= client then
			local otheremote = self.lastemote[player]
			if otheremote
			and player.room == client.room
			and emote.side == otheremote.side
			and otheremote.pair == emote.character
			and emote.pair == otheremote.character then

				emote.pair = otheremote.character
				emote.hscroll = emote.hscroll or 0

				emote.pair_emote = otheremote.emote
				emote.pair_hscroll = otheremote.hscroll
				emote.pair_flip = otheremote.flip
				break
			end
		end
	end

	if not emote.pair_hscroll and emote.hscroll and emote.hscroll ~= 0 then
		emote.pair = emote.character
		emote.pair_hscroll = 100
		emote.pair_emote = "-"
		emote.pair_flip = 0
		emote.hscroll = emote.hscroll or 0
	end
end

function pairing:leave(client)
	self.lastemote[client] = nil
end

return pairing
