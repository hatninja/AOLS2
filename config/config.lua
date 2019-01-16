return function(c)
	--Server information
	c.name = "AOLS2 Server" --Server's name.
	c.desc = "This is a default server." --Description.

	--Connection settings
	c.ip = "0.0.0.0" --The local ip to bind to. "*" is perfectly fine in most situations.
	c.port = 27016 --Your server's port.
	c.maxplayers = 32

	--Software settings
	c.rate = 1/20 --How fast to update the server, in seconds.

	c.verbose = true --Verbose mode shows more descriptive messages. Use if developing.
	c.autorestart = true --Automatically restart when the server experiences a crash.

	c.serverooc = "(*^v^)/"

	--Module: commands
	c.prefix = "/"
	c.helplength = 5

	--Module: motd
	c.motd = "Welcome to a default server!\nSee `/help` for commands."
	c.rules = ""
	c.files = ""

	--Module: antispam
	c.oocmaxnamelength = 30
	c.oocmaxlength = 300
	c.icmaxlength = 300
	c.maxevidence = 18 --By default 18 is one screen's worth.

	--Module: ao2advertiser
	c.ao2msip = "master.aceattorneyonline.com"
	c.ao2msport = 27016
	c.ao2advertise = false
end