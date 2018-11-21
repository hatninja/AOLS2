return {
	motd = "Welcome to a default AO server!\nSee /help for commands.\nSee /rules for the rules.",
	help = [[==Command List==
/area - Get list of rooms.
/area (Number) - Join a room.

/name - Change the name of a courtroom

/whois - Get the list of people around you.
--Other Commands--
/g, /pos, /bg, /doc, /status, /motd, /files, /nick, /desc, /switch, /coinflip, /diceroll, /randomchar]],
	rules = "==The Rules==\n1. Don't be a jerk.\n2. Follow the area descriptions.\n3. Have fun!",

	files = nil,

	musictheme = "Music theme set to (%s)",
	
	OOCnoletters = "Warning: Please enter a name in the second box.",
	OOClongname = "Warning: Your name exceeds %d characters.",
	OOClongmsg = "Warning: Your message exceeds %d characters.",
	
	invalidcommand = "Warning: Invalid command! See /help for a list.",
	
	notanumber = "Warning: You must put in a number!",
	
	--/bg
	invalidbg = "Warning: Invalid bg name!",
	changedbg = "Background changed to '%s'",
	--/room
	invalidroom = "Warning: That room doesn't exist! See the room list by using /rooms",
	joiningheader = "==Joining==",
	changedroom = "Joined %s",
	--/rooms
	roomlistheader = "==Room List==",
	nocourtrooms = "(No courtrooms. You can make one with /newcourt)",
	--/whois
	whoisheader = "==Whois==",
	whoisformat = "[%d] %s '%s'\n",
	
	whoisunotfound = "Warning: User [%d] is not on the server.",
	whoisunoroom = "User [%s] isn't in a room yet.",
	whoisufindroom = "User [%d] is in room %s: \"%s\"",
	whoisuinroom = "User [%d] is %s in position '%s'",
	--/g
	ghelp = "/g (Message) - Global messages appear to everybody in the server, no matter where you are.",
	--/need
	needhelp = "/need (Message) - Sends out an advertisement to everybody in the server.",
	needheader = "Advertisement:\n================\n",
	needfooter = "\n================",
	--/pm
	pmhelp = "/pm (ID) (Message) - Private message. It will appear only to you and the receipient.",
	pmtotarget = "You sent a PM to [%d] saying: %s",
	pmtosender = "[%d] sent a PM to you saying: %s",
	pmnofind = "Warning: No player exists with that ID!",
	
	--/coinflip
	--/diceroll
	
	--/pos
	--/switch
	
	--/bg
	--/name
	--/desc
	
	--still going!
}