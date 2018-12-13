# AOLS2
The successor to AOls. AOLS2 is an Attorney Online server written entirely with Lua.

If you have any feedback on it's implementation, it would be greatly appreciated!

## Requirements
* Lua version 5.1 or above (LuaJIT is reccomended)
* Luasocket

#### Optional
* BitOp or Bit32
Bit operations are required for WebSocket support.

## Running

1. Clone the source to any location.
2. Look in the `config` folder and configure as you like.
3. Run using `lua /path/to/init.lua` or `luajit /path/to/init.lua`

## Features
* Modular design.
* AO 1.x/2.x supported.
* Websockets.
* Automatic restart.

## Commands
