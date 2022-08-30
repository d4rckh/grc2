import ../prelude

import std/nativesockets

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  for listener in server.listeners:
    infoLog $listener
    echo "- IP: " & listener.ipAddress
    echo "- Port: " & $listener.port

let cmd*: Command = Command(
  execProc: execProc,
  name: "listeners",
  aliases: @["l"],
  argsLength: 0,
  usage: @[
    "listeners"
  ],
  description: "Print all listeners",
  category: CCListeners
)