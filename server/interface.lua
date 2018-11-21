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

return interface