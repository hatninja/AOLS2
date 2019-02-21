path = debug.getinfo(1, "S").source:sub(2,-9)

config = {}
dofile(path.."config/config.lua")(config)

if not loadfile(path.."server/arguments.lua")(...) then return end

function verbosewrite(msg) if config.verbose then io.write(msg) end end
verbosewrite(string.format("Running from '%s'\n",path))

--Load dependencies
print "--Loading dependencies--"
if not dofile(path.."server/loader.lua") then return end
verbosewrite "Requirements met!\n"

print "--Starting server--"

dofile(path.."server/constants.lua")

server = dofile(path.."server/server.lua")
server:start()

while not server.kill do
	local st = os.clock()

	local g,err = xpcall(server.update,debug.traceback,server)
	if not g then
		print("FATAL ERROR: "..tostring(err))
		if config.strict then
			if config.autorestart then
				print("RESTARTING!")
				server:reload()
			else
				server:close()
			end
		end
	end

	if interface then
		interface:getch()
		interface:print()
	end

	local time = os.clock()-st
	if time < config.rate then
		socket.sleep(config.rate-time)
	else
		print("Stutter detected! Maybe your update rate is too fast?")
	end
end

print "Safely shut down server!"
