import asyncdispatch

import ../../types

proc execProc*(args: seq[string], server: C2Server) {.async.} =
  for task in server.tasks:
    echo $task.client & " <= " & $task

let cmd*: Command = Command(
  execProc: execProc,
  name: "tasks",
  argsLength: 1,
  usage: @[
    "tasks",
  ],
  description: "View all tasks sent",
  category: CCTasks
)