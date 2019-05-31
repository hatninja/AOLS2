local process = ...

local lobby = {
	name = "Lobbies"
}

function lobby:init()
	self.parent = process.modules["rooms"]


	process:registerCallback(self,"command", 4,self.command)
	
	process:registerCallback(self,"event_play", 3,self.block)
	process:registerCallback(self,"item_add", 3,self.block)
	process:registerCallback(self,"item_edit", 3,self.block)
	process:registerCallback(self,"item_remove", 3,self.block)
end

function lobby:block(client, event)
	if client.room and client.room.kind == "lobby" and not client.mod then return true end
end


function lobby:command(client, cmd,str,args)
	if client.room and client.room.kind ~= "lobby" then return end
	if cmd == "bg" or cmd == "bd" or cmd == "cr"  then
		process:sendMessage(client,"You cannot change the BG in this room!")
		return true
	end
	if cmd == "doc" and args[1] then
		process:sendMessage(client,"You cannot change the doc in this room!")
		return true
	end
	if cmd == "status" then
		process:sendMessage(client,"You cannot change the status in this room!")
		return true
	end
	if cmd == "lock" then
		process:sendMessage(client,"You cannot change the lock in this room!")
		return true
	end
end

return lobby