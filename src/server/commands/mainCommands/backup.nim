import std/[ 
  tables, 
  asyncdispatch,
  os,
  marshal
]

import ../../types



proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  echo "this command is broken sorry"
  # var clientsToSave: seq[C2Client] = @[]
  # var tasksToSave: seq[RawTask] = getRawTasks server.tasks

  # for client in server.clients:
  #   var tempClient: C2Client = new C2Client
  #   tempClient[] = client[]
  #   tempClient.server = nil
  #   clientsToSave.add tempClient

  # writeFile("save/clients.txt", $$clientsToSave) 
  # writeFile("save/tasks.txt", $$tasksToSave) 


let cmd*: Command = Command(
  execProc: execProc,
  name: "backup",
  aliases: @["bkp", "save"],
  argsLength: 0,
  usage: @["backup"],
  description: "backup data",
  category: CCNavigation
)