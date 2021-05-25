--Special handling
local translator = {
	lookup = {}
}

function translator.genLookup(lang,t)
	if not translator.lookup[lang] then
		translator.lookup[lang] = {}
	end

	local lookup = translator.lookup[lang]
	for k,v in pairs(t) do
		lookup[k] = v
	end
end

function translator.lookup(lang,key)
	if not translator.lookup[lang] then
		warn ("Language \""..lang.."\" not found for key: "..key)
		return key
	end
	local str = translator.lookup[lang][key]
	return str or key
end

--Format using a table
--Possible multi-table support?
function translator.format(str, ...)
	local t
	if ... and type(...) == "table" then
		t = ...
	else
		t = {...}
	end

	local fstr = str
	if type(str) == "table" then
		str = table.concat(str,"\t")
	end
	for k,v in pairs(t) do
		fstr = fstr:gsub("%$%{([_0-9a-zA-Z]+)%}",
		function(str)
			local v = tonumber(str) and t[tonumber(str)] or t[str]
			if type(v) == "function" then v = v(t) end
			if type(v) == "table" then return "("..table.concat(v..",")..")" end
			if v == "nil" then return "${"..str.."}" end
			return v
		end)
	end
	return fstr
end

function translator.globalise()
	l = translator.lookup
	f = translator.format
end

return translator
