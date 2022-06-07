import asyncdispatch, tables, strutils

import ../../types

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  if args.len() == 0:
    echo "-- server config --"
    echo "handle_reconnections: " & $parseBool(server.configuration.getOrDefault("handle_reconnections", "true"))
    echo " - true: the server will restore clients when they reconnect; false: server will create new client objects for each connection (you will end up with duplicates)"
  elif args.len() == 3:
    server.configuration[args[1]] = args[2]
    echo "set '" & args[1] & "' to '" & args[2] & "'"
let cmd*: Command = Command(
  execProc: execProc,
  name: "config",
  usage: @["config", "config set [key] \"[value]\""],
  description: "View and change config of the c2 server",
  category: CCNavigation
)