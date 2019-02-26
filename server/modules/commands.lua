--Commands handler.
--[[
It implements these two things.
"command" event
/help
]]

local process = ...

local commands = {
	name = "Command",

	help = {
		{"help","(page)","Get help with commands.","Put in any command name to read more about it."},
	},
}

function commands:init()
	--Generate help menu.
	self.helptable = {}
	for k,module in pairs(process.modules) do
		if type(module.help) == "table" then
			for k,v in pairs(module.help) do
				table.insert(self.helptable,v)
			end
		end
	end
	self.prefix = config.prefix or "/"
	
	process:registerCallback(self,"ooc",4,self.handle)
	process:registerCallback(self,"emote",4,self.handle)
	process:registerCallback(self,"command",4,self.helpcmd)
end

function commands:handle(client,data)
	local message = data.dialogue or data.message
	if message:sub(1,#self.prefix) == self.prefix then
		local s,e = message:find("%s+")
		local cmd = message:sub(#self.prefix+1,(s or 0)-1)
		local str = ""
		if e then
			str = message:sub(e+1,-1)
		end

		local args = {}
		for argument in message:gmatch("%s+(%S+)") do
			table.insert(args,argument)
		end

		if process:event("command",client,cmd,str,args, data.name) then --Means no callbacks returned.
			process:sendMessage(client,"Command \""..tostring(cmd).."\" not recognized! See /help for list of commands.")
		end
		return true
	end
end

function commands:helpcmd(client, cmd,str,args)
	if cmd == "help" then
		local name = args[1]
		if not name then
			local msg = "Use /help (command) to get more detailed info.\n~~Commands List~~\n"
			for i,v in ipairs(self.helptable) do
				msg=msg..self.prefix..v[1]..", "
			end
			msg = msg:sub(1,-3)
			process:sendMessage(client,msg)
			return true
		else
			local msg = "~~Help~~\n"
			for i,v in ipairs(self.helptable) do
				if v[1] == name then
					msg=msg..(self.prefix..name).." "..(v[2] or "")
					msg=msg.."\n"
					if v[4] then
						msg=msg..tostring(v[4])
					else
						msg=msg..tostring(v[3])
					end
					process:sendMessage(client,msg)
					return true
				end
			end
			msg=msg.."Could not find help page for \""..name.."\""
			process:sendMessage(client,msg)
			return true
		end		
	end
end

return commands