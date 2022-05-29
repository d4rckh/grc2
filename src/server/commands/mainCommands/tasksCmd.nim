import asyncdispatch, tables, ws

import ../../types

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  for task in server.tasks:
    echo $task.client & " <= " & $task

let cmd*: Command = Command(
  execProc: execProc,
  name: "tasks",
  argsLength: 0,
  usage: @[
    "tasks",
  ],
  description: "View all tasks sent",
  category: CCTasks
)