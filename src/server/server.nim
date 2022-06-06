import asyncdispatch, asyncfutures
import types, logging, cli, ../utils

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
    import httpapi/httpserver
    asyncCheck startHttpAPI(server)
runForever()
