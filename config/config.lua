function load_config(c)
	c.name = "AOLS2 Server" --Server's name.
	c.desc = "This is a default server." --Description.

	c.ip = "0.0.0.0" --The local ip to bind to.
	c.port = 27016 --Your server's port.
	c.maxplayers = 32

	c.rate = 1/20 --How fast to update the server, in seconds.

	c.serverooc = "(*^v^)/"
	c.oocmaxnamelength = 30
	c.oocmaxlength = 300
	c.icmaxlength = 300

	c.maxevidence = 18 --Maximum evidence that can be had at once. By default 18 is one screen's worth.

	c.verbose = false --Verbose mode shows more descriptive messages. Use if developing.
	c.interface = false --Interface toggle which allows interaction via the terminal.
	c.autorestart = true --Automatically restart when the server experiences a crash.

	c.advertise = false --Set as true to advertise to the master server.

	--The master server location to use for AO2.
	c.ao2msip = "master.aceattorneyonline.com"
	c.ao2msport = 27016
end