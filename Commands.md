## List of Commands
**/motd, /rules, /files** -
Each display a text message if it is set.
`/motd` is the message you get when you join.

**/help** -
Displays a list of all commands. This may change between different server setups.

**/help (command)** -
Opens an information page on a specific command.

**/area (room id)** -
Move to a specific area as shown by `/areas`

**/area** or **/areas** -
Displays the area list.

**/getarea (room id)** -
Gets the list of people in the room with you. Optionally, specify a room id to get the list of that room.

**/getareas** -
Lists every user in every room.

**/whois (user id)** -
Returns your user information.

**/g (message)** -
Sends a global message. Anyone in the server can see it.

**/pm (user id) (message)** -
Sends a private message to a user.

**/self (status)**-
Appends a status tag to your nickname.

**/char (name)** -
Selects a character by name.

**/charlist** -
Shows the list of characters that the server supports.

**/randomchar** -
Selects a random character for you.

**/pos** -
Sets your character's position within the background.
Currently supported: def, pro, wit, jud, hld, hlp, jur

**/desk** -
Sets your desk's visibility.
0 forces desk off, 1 forces desk on.
No arguments sets it back to default.

**/zoom** -
Toggles speedlines when using an emote.

**/userpair (user id)** -
Sets your pair to a specific user. If your pair connects, you will be paired together regardless of character.

**/autopair** -
Toggles autopair mode. You automatically pair with players who have autopair enabled.

**/bg (name)** -
Sets the background for the room.

**/bglist** -
Shows list of the backgrounds that the server supports.

**/localbg (dir)** -
Changes the background locally. I.e. Nobody else can see it, and is not restricted to the list.

**/bd (name)** -
Sets a backdrop background  for the room.

**/bdlist** -
Shows list of the backdrops.

**/cr (name)** -
Sets a court background for the room.

**/crlist** -
Shows list of the courts.

**/status** -
Sets the status of a courtroom.

**/rename** -
Renames a room if it is renamable.

**/doc (link)** -
Sets the room's doc.
Use with no arguments to return the doc.

**/steno** -
Toggles steno mode. Steno mode fixes common capitialization and punctuation errors. It also hides messages in double brackets.

**/rejoin** -
Reconnects you as your ghost player if it exists.

**/coinflip** -
Flips a coin. You get Heads or Tails. The result will be announced in the room.

**/diceroll (sides)** -
Rolls a 6-sided die by default. You can specify how many sides the die has. The result will be announced in the room.

**/timer (minutes)**
Use without an argument to use it as a stopwatch. Add minutes to run an automatic timer.

**/lock (password)** -
Locks a room with a password. Users are required to use a key to enter. (See Below.)

**/key (password)** -
Allows you to enter any room that uses the same password.

**/server** -
Returns the server software and version.

#### Mod commands
**/modpass (passcode)** -
Logs you in as moderator.

**/unmodme** -
Removes your moderator status.

**/kick (id)** -
Boots the user off the server.

**/ban (id)** -
Bans the users ip from the server, they will not be able to rejoin.
Their IP will be given once you do this.

**/unban (ip)** -
Unbans the specified IP, users using the ip will be able to join again.

**/mute (user id)** -
Stops a user from using IC features.

**/unmute (user id)** -
Unmutes said user.

**/move (user id) (room id)** -
Moves a user to the specified room.

**/trap (user id) (room id)** -
Traps a user to the specified room, they will not be able to change rooms.
You can omit room id, to lock the user where they are.

**/untrap (user id)** -
Untraps a user.

**/modlock** -
Locks a room so only moderators can enter. Use again to disable the lock.

**/reload** -
Reloads the server. This will disconnect every client.
