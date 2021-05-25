path = debug.getinfo(1, "S").source:sub(2,-9)
config = {}

--Check for config.lua
local f = io.open(path.."config/config.lua")
if not f then
	print("Configuration not found at 'config/', unable to start.")
	return
end
f:close()


print "--Run Sequence--"

	dofile(path.."config/config.lua")(config)

	if not loadfile(path.."server/arguments.lua")(...) then
		return
	end

	--Set require paths to be relative to 'server/'
	package.path = path.."server/?.lua;" .. package.path
	--Unpack compatibility
	if table.unpack then unpack = table.unpack end

	local log = require("logging")
	log.globalise()
	verbose "Initialized logging tools.\n"

	local translator = require("translator")
	translator.globalise()
	verbose "Initialized translating tools.\n"

	if not require("dependencies") then return end


print "--Starting server--"

	require("constants")
	server = require("server")
	server:start()


print "--Start finished, now running--"

	--Update loop.
	while not server.kill do
		local st = os.clock()

		local g,err = xpcall(server.update, debug.traceback)
		if not g then
			print(tostring(err))
			if config.strict then
				if config.autorestart then
					print("RESTARTING!")
					server:reload()
				else
					server:close()
					return
				end
			end
		end

		local time = os.clock()-st
		if time < config.rate then
			socket.sleep(config.rate-time)
		else
			print("Stutter detected!","+"..tostring((time-config.rate)*1000).."ms")
		end

	end

print "Safely shut down server!"
