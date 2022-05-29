import asyncdispatch, tables

import ../../types

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  for client in server.cli.handlingClient: 
    echo @client

let cmd*: Command = Command(
  execProc: execProc,
  name: "info",
  argsLength: 0,
  usage: @["info"],
  cliMode: @[ClientInteractMode],
  description: "Get more info about a client",
  category: CCClientInteraction
)