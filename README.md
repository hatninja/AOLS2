# AOLS2
AOLS2 is a chatroom server written entirely in Lua. It is the successor to [AOls](https://github.com/hatninja/AOls) and is meant for use with the fan-game Attorney Online 2.

The server is designed to be very modular and to make the addition of new features easy.

If you have any feedback on it's implementation, it would be greatly appreciated!

## Requirements
* Any Lua version 5.1 and above (LuaJIT is recommended)
* Luasocket

#### Optional
* BitOp or Bit32  
Bit library operations are required for WebSocket support.

## Running

1. Clone the source to any location.
2. Rename `config.default/` to `config/`, and configure as you like.
3. Run using `lua /path/to/init.lua` or `luajit /path/to/init.lua`

## Features
* Very modular and configurable.
* AO 1.0 to 2.8.x protocols supported, as well as Websockets.
* Automatic restart on crashes.
* Extensive core modules that implement AO2 server functionality.
* Hot-reloading of modules supported.


## Modules
Found in [server/modules/](server/modules). Modules extend the basic functionality of the server using callbacks, and enable a wide range of features to work through events.

#### Commands
Commands are implemented via Modules, for this repository's list, see [Commands](Commands.md).

## Protocols
Found in [server/protocols/](server/protocols). Protocols are the translation layer between raw socket messages and the server process itself. Using message objects that can pass-through back to clients, this allows the server to function independently of what a protocol may require.  
