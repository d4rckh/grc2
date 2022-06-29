import std/[
  marshal, 
  tables, 
  asyncdispatch,
  os
]

import ../../types

proc getRawTasks(tasks: seq[Task]): seq[RawTask] =
  for task in tasks:
    result.add RawTask(
      clientHash: task.client.hash,
      id: task.id,
      action: task.action,
      status: task.status,
      arguments: task.arguments,
      output: task.output
    )

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  var clientsToSave: seq[C2Client] = @[]
  var tasksToSave: seq[RawTask] = getRawTasks server.tasks

  for client in server.clients:
    var tempClient: C2Client = new C2Client
    tempClient[] = client[]
    tempClient.server = nil
    clientsToSave.add tempClient

  writeFile("save/clients.txt", $$clientsToSave) 
  writeFile("save/tasks.txt", $$tasksToSave) 

let cmd*: Command = Command(
  execProc: execProc,
  name: "backup",
  aliases: @["bkp", "save"],
  argsLength: 0,
  usage: @["backup"],
  description: "backup data",
  category: CCNavigation
)