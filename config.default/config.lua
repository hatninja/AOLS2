return function(c) --Note: Every variable here is printable as a command, via misc.
	
	--Server information
	c.name = "AOLS2 Server" --Server's name.
	c.desc = "This is a default server." --Description.

	--Connection settings
	c.ip = "0.0.0.0" --The local ip to bind to. "*" is perfectly fine in most situations.
	c.port = 27016 --Your server's port.
	c.maxplayers = 32

	--Software settings
	c.rate = 1/8 --How fast to update the server, in seconds.

	c.verbose = true --Verbose mode shows more descriptive messages. Use if developing.
	c.autorestart = true --Automatically restart when the server experiences a crash.
	c.strict = true --If the server isn't strict, it will ignore errors and keep running.
	c.monitor = false --Reading of client-sent packets.

	c.serverooc = "(*^v^)/"

	--Module: motd
	c.motd = "Welcome to a default server!\nSee `/help` for commands."
	c.rules = ""
	c.files = ""

	--Module: commands
	c.prefix = "/" --The prefix of commands. All clients assume "/", so change with caution.

	--Module: clientlimit
	c.multiclients = 3 --The maximum amount of clients allowed per ip/hardwareid

	--Module: charhelper
	c.autospectate = false

	--Module: misc
	c.shuffle = false

	--Module: antispam
	c.maxnamelength = 30
	c.maxmsglength = 400
	c.maxevidence = 18*2 --By default 18 is one screen's worth.

	--Module: room_status
	c.maxrename = 30 --The maxmimum characters a renamed room can have.
	
	--Module: room_navigation
	c.listareas = true --Automatically list areas when connected.

	--Module: ao2advertiser
	c.ao2msip = "master.aceattorneyonline.com"
	c.ao2msport = 27016
	c.ao2advertise = false
end