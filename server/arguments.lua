for i,v in ipairs({...}) do
    if v:find("verbose") then
        config.verbose=true
	elseif v:find("interface") then
		config.interface=true
	elseif v:find("nointerface") then
		config.interface=false
    elseif v:find("help") then
        return
    end
end
return true
