local process = ...

local pairing = {}

function pairing:init()
	self.parent = process.modules["rooms"]

	self.lastemote = {}

	process:registerCallback(self,"emote", 3,self.emote)
	process:registerCallback(self,"player_leave", 3,self.leave)
	process:registerCallback(self,"player_move", 3,self.leave)
end

function pairing:emote(client, emote)
	self.lastemote[client] = emote

	for player in process:eachPlayer() do
		if player ~= client then
			local lastemote = self.lastemote[player]
			if lastemote
			and player.room == client.room
			and lastemote.pair == client.character
			and emote.pair == player.character 
			and emote.side == lastemote.side then
				self:print("PAIRING\t"..lastemote.pair.."\t"..emote.pair)
				emote.pair_emote = lastemote.emote
				emote.pair_hscroll = lastemote.hscroll
				emote.pair_flip = lastemote.pair_flip
				break
			end
		end
	end
end

function pairing:leave(client)
	self.lastemote[client] = nil
end

return pairing