import std/[
  asyncdispatch, 
  tables
]

import ../../types, ../../communication

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  for client in server.cli.handlingClient:  
    # just update the token info
    let task = await client.sendClientTask("tokinfo")
    if not task.isNil(): 
      await task.awaitResponse()

let cmd*: Command = Command(
  execProc: execProc,
  name: "tokeninfo",
  argsLength: 0,
  usage: @["tokeninfo"],
  cliMode: @[ClientInteractMode],
  description: "Get info about own process windows token",
  category: CCClientInteraction,
  requiresConnectedClient: true
)