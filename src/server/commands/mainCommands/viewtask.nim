import asyncdispatch, tables, ws

import ../../types, ../../handleResponse

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  for task in server.tasks:
    if $task.id == args[0]:
      handleResponse(task.client, true, task.output)

let cmd*: Command = Command(
  execProc: execProc,
  name: "viewtask",
  argsLength: 0,
  usage: @[
    "viewtask [taskid]",
  ],
  description: "View all tasks sent",
  category: CCTasks
)