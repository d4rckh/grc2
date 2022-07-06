import asyncdispatch, strutils, tables, json

import ../../types
import ../../logging
import ../../communication

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  for client in server.cli.handlingClient:
    let task = await client.sendClientTask("rmdir", %*[ args[0] ])
    if not task.isNil(): await task.awaitResponse()

let cmd*: Command = Command(
  execProc: execProc,
  name: "rmdir",
  argsLength: 0,
  usage: @["rmdir", "rmdir \"[dir]\""],
  cliMode: @[ClientInteractMode],
  description: "Delete directory",
  category: CCClientInteraction,
  requiresConnectedClient: true
)