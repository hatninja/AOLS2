print ("Lua Version - 👍 ("..(jit and jit.version or _VERSION)..")")


verbose "Luasocket - "

local found,d = pcall(require,"socket")
if found then
	verbose ("👍 ("..d._VERSION..")\n")
	socket = d
else
	verbose "👎\n"
	print "luasocket is required to run! Make sure it is installed for the lua version above."
	return false
end


verbose "Bit - "

local found,d = pcall(require,"bit")
if found then
	verbose "👍 (LuaJIT/5.1 BitOp)\n"
	bit = d
else
	local found2,d = pcall(require,"bit32")
	if found2 then
		verbose "👍 (Lua 5.2 Bit32)\n"
		bit = d
	else
		verbose "👎\n"
		warn "AOLS2 requires a bit operation library for websocket support!"
	end
end

verbose "Requirements met!\n"

return true
