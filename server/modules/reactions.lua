--Reactions. Allows you to use different sounds on the fly.
local process = ...

local reactions = {
	help = {
		{"react","(sfx)","Override the sound effect in your next emote.","Shorthand 'reactions' exist, discoverable via /reactions."},
		{"reactlist","(sfx)"}
	}
}

function reactions:init()
	process:registerCallback(self,"emote",2,self.handle)
	process:registerCallback(self,"command",3,self.command)

	self.reactions = {}
	if config.reactions then
		for i=1,#config.reactions,2 do
			self.reactions[config.reactions[i]] = config.reactions[i+1]
		end
	end
end

function reactions:handle(client, emote)
	if client.nextreact then
		emote.sfx_name = client.nextreact
		emote.sfx_delay = 0
		if not emote.pre_emote then
			emote.pre_emote = "sfx"
		end
	end
end

function reactions:command(client, cmd,str,args)
	if cmd == "react" then
		if str then
			local sound = self.reactions[str] or str

			client.nextreact = sound
			process:sendMessage(client,"Reaction set to '"..sound.."'")
		else
			client.nextreact = nil
			process:sendMessage(client,"Removed reaction.")
		end
		return true
	end
	if cmd == "reactlist" or cmd == "rlist" then
		local list = ""
		local reactions = self.reactions

		for k,sfx in pairs(reactions) do
			list = list .. "\"" .. k .. "\": " .. sfx .. "\n"
		end

		list = list:sub(1, -2)
		process:sendMessage(client,list)
		return true
	end
end

return reactions
