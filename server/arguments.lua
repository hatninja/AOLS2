for i,v in ipairs({...}) do
    if v:find("verbose") then
        config.verbose=true
    elseif v:find("help") then
        return
    end
end

return true
