function getkey()
    local char = getch()
    if char > 31 and char < 127 then
        return string.char(char)
    elseif char == 27 then
        local a = getch()
        if a == "[" then
            local b = getch()

            --[[
            ;5 - Ctrl
            ;1 - Super
            ;2 - Alt
            ;3 - Shift
            ]]
            if b == "2" then return "insert"
            elseif b == "3" then return "delete"
            elseif b == "5" then return "pageup"
            elseif b == "6" then return "pagedown"

            elseif b == "A" then return "up"
            elseif b == "B" then return "down"
            elseif b == "C" then return "right"
            elseif b == "D" then return "left"
            elseif b == "F" then return "end"
            elseif b == "H" then return "home"
            end
        end
    elseif char == 127 then
        return "backspace"
    elseif char == 13 then
        return "enter"
    end
end

function verbosewrite(msg)
    if verbose then io.write(msg) end
end

function string.split(input,delimit)
	local t = {}
	local string = tostring(input)
	local delimiter = tostring(delimit) or ""
	if delimiter and delimiter ~= "" then
		while string:find(delimiter) do
			local beginning, ending = string:find(delimiter)
			table.insert(t,string:sub(1,beginning-1))
			string = string:sub(ending+1)
		end
		if not string:find(delimiter) then
			if string ~= "" then
				table.insert(t,string)
			end
		end
	else
		for i = 1, #string do
			table.insert(t,string:sub(i,i))
		end
	end

	return t
end

function table.find(t,val)
	if t then
		for k,v in pairs(t) do
			if val == v then
				return k
			end
		end
	end
end

function loadlist(dir)
	local t = {}
	local file = io.open(dir)
	if file then
		for line in file:lines() do
			table.insert(t,line)
		end
	end
	return t
end

function savelist(list,dir)
	local file = io.open(dir,"w")
	for i=1,#list do local v = list[i]
		if v then
			file:write(v.."\n")
		end
	end
	file:close()
end
