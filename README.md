# AOLS2
The successor to AOls, an Attorney Online server written entirely with Lua.

Although designed to be AO2 server, AOLS2 goal is to be extremely flexible in it's functionality.

Eventually, running AO2 and AC simultaneously.

If you have any feedback based on it's implementation, it would be greatly appreciated!

## Requirements
* Lua version 5.1 or above (LuaJIT is reccomended)
* Luasocket

####Optional
* BitOp or Bit32
Bit operations are required for AO 1.x versions and WebSocket support.
* Lua-getch
Getch is required to support the interface.

## Running

1. Clone the source to any location.
2. Configure your server by looking in the `config` folder.
3. Run using `lua /path/to/AOLS2/init.lua` or `luajit /path/to/AOLS2/init.lua`

##Features
