local log = {}

--Printing extra information that developers may find useful.
function log.verbose(msg)
	if config.verbose then
		io.write(msg)
	end
end

local oprint = print
function log.print(...)
	return oprint(...)
end

function log.warn(msg)
	oprint("[Warning] "..tostring(msg))
end
function log.serror(msg)
	oprint("[Error] "..tostring(msg))
end

function log.trace(level)
	local info = debug.getinfo((level or 1)+1)
	io.write(tostring(info.short_src)..":"..tostring(info.currentline).." ")
end

function log.globalise()
	verbose = log.verbose
	print = log.print
	warn = log.warn
	trace = log.trace
end

return log
