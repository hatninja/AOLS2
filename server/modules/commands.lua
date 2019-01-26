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

		if process:event("command",client,cmd,str,args) then --Means no callbacks returned.
			process:sendMessage(client,"Command \""..tostring(cmd).."\" not recognized! See /help for list of commands.")
		end
		return true
	end
end

function commands:helpcmd(client, cmd,str,args)
	if cmd == "help" then
		local length = config.helplength or 5
		local page = tonumber(args[1])
		local name = args[1]
		local msg
	
		if not name and not page then page = 1 end

		if page then
			msg = "~~Help: Page "..page.." of "..math.ceil(#self.helptable/length).."~~"
			for i=1+(page-1)*length, page*length do
				local entry = self.helptable[i]
				if i <= #self.helptable and type(entry) == "table" then
					msg=msg.."\n"
					msg=msg..(self.prefix..entry[1]).." "..entry[2].."\n\t"..tostring(entry[3])
				end
			end
			process:sendMessage(client,msg)
			return true
		else
			msg = "~~Help~~\n"
			for i,v in ipairs(self.helptable) do
				if v[1] == name then
					msg=msg..(self.prefix..name).." "..(v[2] or "")
					msg=msg.."\n"
					if v[4] then
						msg=msg..tostring(v[4])
					else
						msg=msg..tostring("No page exists for this command.")
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