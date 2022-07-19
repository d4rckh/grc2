import std/[
  asyncdispatch, 
  strutils, 
  asyncfutures, 
  tables, 
  nativesockets
]

import ../../types, ../../listeners/index, ../../logging

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =

  if len(args) < 2:
    errorLog "you must specify a listener type and a name (check 'help startlistener' for more info)"
    return

  var listenerType: string = args[0]
  var listenerName: string = args[1]

  let port = flags.getOrDefault("port", flags.getOrDefault("p", ""))
  let ip = flags.getOrDefault("ip", flags.getOrDefault("i", ""))
  
  if port == "" and ip == "":
    errorLog "--ip and --port flags are required"
    return

  for listener in listeners:
    if listener.name == listenerType:
      var params: Table[string, string]
      discard server.startListener(
        listenerName,
        tcp.listener,
        ip, Port parseInt(port), params
      )
      
let cmd*: Command = Command(
  execProc: execProc,
  name: "startlistener",
  aliases: @["sl"],
  argsLength: 1,
  usage: @[
    "startlistener [listenerType] [listerName] [..options]",
  ],
  description: "Start a new listener",
  category: CCListeners
)
