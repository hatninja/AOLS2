verbosewrite("Lua Version - 👍 ("..(jit and jit.version or _VERSION)..")\n")


verbosewrite "Luasocket - "

local found,d = pcall(require,"socket")
if found then
	verbosewrite("👍 ("..d._VERSION..")\n")
	socket = d
else
	verbosewrite "👎\n"
	print "Error: luasocket is required to run! Make sure it is installed in the right version."
	return
end


verbosewrite "Bit - "

local found,d = pcall(require,"bit")
if found then
	verbosewrite "👍 (LuaJIT/5.1 BitOp)\n"
	bit = d
else
	local found2,d = pcall(require,"bit32")
	if found2 then
		verbosewrite "👍 (Lua 5.2 Bit32)\n"
		bit = d
	else
		verbosewrite "👎\n"
		print "Warning: AOLS2 requires a bit operation library for websocket support!"
	end
end


return true
