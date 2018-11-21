--[[
Example room:
	{
		name = "Room",
		desc = "Very roomy",
		bg = "default",
		music = "Prelude(AA).mp3",
		kind = "court" --"court", "lobby", "echo"
		bglock = true,
		modlock = false,
		lock = false,
		evidence = {
			{"Evidence Name","Description","icon.png"},
		}
	}
]]

return {
	{
		name="Lobby",
		desc="",
		bg="default",
		music="No Music",
		kind="lobby",
	},
	{
		name="A Courtroom",
		desc="",
		bg="gs4",
		music="No Music",
		kind="court",
	}
}