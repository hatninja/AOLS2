path = debug.getinfo(1, "S").source:sub(2,-9)
config = {}

function verbosewrite(msg)
	if config.verbose then
		io.write(msg)
	end
end

print(path)
print "--Loading configuration--"

	dofile(path.."config/config.lua")(config)

	if not loadfile(path.."server/arguments.lua")(...) then
		return
	end


print "--Loading dependencies--"

	if not dofile(path.."server/loader.lua") then return end
	verbosewrite "Requirements met!\n"


print "--Starting server--"

	--Set require paths to be relative to 'server/'
	package.path = path.."server/?.lua;" .. package.path

	require("constants")
	server = require("server")
	server:start()

	--Do update loop.
	while not server.kill do
		local st = os.clock()

		local g,err = xpcall(server.update, debug.traceback)
		if not g then
			print("FATAL ERROR: "..tostring(err))
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
			print("Stutter detected! Maybe your update rate is too fast?")
		end
	end

print "Safely shut down server!"
