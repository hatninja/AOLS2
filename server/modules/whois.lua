local process = ...

local whois = {

	help = {
		{"whois","","Get player information."},
		{"getarea","","Gets list of people."}
	}
}

function whois:init()
	process:registerCallback(self,"command",3,self.command)
end

function whois:command(client, cmd,str,args)
	if cmd == "whois" then
		return true
	end
	if cmd == "getarea" then
		return true
	end
end

return whois