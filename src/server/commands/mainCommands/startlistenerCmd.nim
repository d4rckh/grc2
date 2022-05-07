import asyncdispatch, strutils, asyncfutures, tables

import ../../types, ../../listeners/tcp, ../../logging

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =

  if len(args) < 1:
    errorLog "you must specify a listener type, supported: tcp (check 'help startlistener' for more info)"
    return

  var listenerType: string = args[0]

  case listenerType.toLower():
  of "tcp":
    let port = flags.getOrDefault("port", flags.getOrDefault("p", ""))
    let ip = flags.getOrDefault("ip", flags.getOrDefault("i", ""))
    
    if port == "" and ip == "":
      errorLog "--ip and --port flags are required for this listener type"
      return

    asyncCheck server.createNewTcpListener(parseInt(port), ip)
          
let cmd*: Command = Command(
  execProc: execProc,
  name: "startlistener",
  aliases: @["sl"],
  argsLength: 1,
  usage: @[
    "startlistener [listenerType] [..options]",
    "startlistener tcp --ip/-i:[ip] --port/-p:[port]"
  ],
  description: "Start a new listener",
  category: CCListeners
)
