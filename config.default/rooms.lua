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
		kind="rp",
		renamable=true,
	}
	t[2] = {
		name="Random",
		bg="gs4",
		kind="rp",
		renamable=true,
		iniswap=true,
	}
	t[3] = {
		name="Secret Court",
		bg="gs4night",
		kind="rp",
		hidden=true,
	}

	--The default room id that players will join.
	return 1
end
