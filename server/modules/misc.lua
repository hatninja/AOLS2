local misc = {}

function misc:init(process)
	--Quick and simple reload!
	process:registerCallback(self,"call_mod",5,function()
		self:print("Reloading the server now!")
		process.server:reload()
	end)
end

return misc