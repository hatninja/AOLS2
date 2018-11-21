path = debug.getinfo(1, "S").source:sub(2,-9)

dofile(path.."config/config.lua")
config = {}
load_config(config)

if not loadfile(path.."server/arguments.lua")(...) then return end

function verbosewrite(msg) if verbose then io.write(msg) end end
verbosewrite(string.format("Running from '%s'\n",path))

--Load dependencies
if not dofile(path.."server/loader.lua") then return end
verbosewrite "Requirements met!\n"

print "Starting server..."

server = dofile(path.."server/server.lua")
server:start()

if config.interface then interface = dofile(path.."server/interface.lua") end

while not server.kill do
	local st = os.clock()

	local g,err = pcall(server.update,server)
	if not g then
		print("FATAL ERROR:\n"..tostring(err))
		server:close()
	end
	if server.kill and config.autorestart then
		print("RESTARTING!")
		server = nil
		server = dofile("server/server.lua")
		server:start()
	end

	if interface then
		interface:getch()
		interface:print()
	end

	local time = os.clock()-st
	if time < config.rate then
		socket.sleep(config.rate-time)
	else
		verbosewrite("Stutter detected!\n")
	end
end
if interface then interface:close() end

print "Safely shut down server!"
