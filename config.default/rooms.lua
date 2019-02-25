return function(t)
	t[1] = {
		name="Lobby",
		desc="It's the lobby",
		bg="default",
		music="No Music",
		kind="lobby",
	}
	t[2] = {
		name="Courtroom",
		bg="gs4",
		kind="court",
		renamable=true,
	}
	t[3] = {
		name="Secret Court",
		bg="gs4night",
		kind="court",
		hidden=true,
	}

	return t[1]
end