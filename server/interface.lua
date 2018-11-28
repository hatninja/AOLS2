local interface = {}
interface.buffer = ""

os.execute("stty raw -echo") 

function interface:close()
	os.execute("stty sane") 
end

function interface:getch()
	local char = getch()
	if char > 31 and char < 127 then
		self.buffer = self.buffer .. string.char(char)
	elseif char == 127 then
		self.buffer = self.buffer:sub(1,-2)
	elseif char == 13 then
		if self.buffer == "q" then
			server:close()
		end
		self.buffer = ""
	elseif char ~= 0 then
		print(char)
	end
end

function interface:print()
	io.write("\x1B[G") --Set cursor position to 1
	io.write("$: "..self.buffer)
	io.flush()
	
	io.write("\x1B[2K") --Clear the current line.
	io.write("\x1B[G")
end

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


return interface