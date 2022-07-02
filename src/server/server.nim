import std/[
  os,
  asyncdispatch,
  asyncfutures,
  marshal
]
import types, logging, communication, cli, ../utils

infoLog "initializing c2 server"

var commands: seq[Command] = @[]

importDirectory("src/server/commands/mainCommands", "commands/", "mainCommands")
importDirectory("src/server/commands/interactCommands", "commands/", "interactCommands")
loadCommands("src/server/commands/mainCommands")
loadCommands("src/server/commands/interactCommands")

let server = C2Server(
  cli: C2Cli(
    handlingClient: @[],
    mode: MainMode,
    commands: commands
  )
)

# if fileExists "save/clients.txt":
#   infoLog "found backup; restoring clients backup"
#   let clientBContents = readFile("save/clients.txt")
#   let newClients: seq[C2Client] = to[seq[C2Client]](clientBContents) 
#   for client in newClients:
#     client.server = server
#     client.connected = false
#   server.clients = newClients
#   successLog "restored " & $server.clients.len & " clients successfully"

# if fileExists "save/tasks.txt":
#   infoLog "found backup; restoring tasks backup"
#   let taskBContents = readFile("save/tasks.txt")
#   let rawTasks: seq[RawTask] = to[seq[RawTask]](taskBContents) 
#   var newTasks: seq[Task] = @[]
#   for task in rawTasks:
#     newTasks.add Task(
#       client: server.getClientById(task.clientId),
#       id: task.id,
#       action: task.action,
#       status: task.status,
#       arguments: task.arguments,
#       output: task.output
#     )

#   server.tasks = newTasks
#   successLog "restored " & $server.tasks.len & " tasks successfully"

proc ctrlc() {.noconv.} =
  if server.cli.interactive or not server.cli.initialized:
    quit 0
  else:
    for task in server.tasks:
      task.future[].complete()
setControlCHook(ctrlc)

when defined(debug):
    import listeners/tcp
    asyncCheck createNewTcpListener(server, 1337, "127.0.0.1")
asyncCheck procStdin(server)
when defined(debug):
  # import httpapi/httpserver
  # asyncCheck startHttpAPI(server)
  import tcpApi
  asyncCheck startTcpApi(server)
runForever()
