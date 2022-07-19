import std/[
  asyncdispatch, 
  strutils, 
  asyncfutures, 
  tables, 
  nativesockets
]

import ../../types, ../../listeners/index, ../../logging

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =

  when defined(debug):
    if len(args) < 1:
      errorLog "you must specify a name (check 'help stoplistener' for more info)"
      return

    var listenerName: string = args[0]
    var listenerToStop: ListenerInstance
    for listener in server.listeners:
      if listener.title == listenerName:
        listenerToStop = listener

    server.stopListener(listenerToStop)

  else:
    echo "command only available in debug mode"

let cmd*: Command = Command(
  execProc: execProc,
  name: "stoplistener",
  aliases: @["stopl"],
  argsLength: 1,
  usage: @[
    "startlistener[listerName]",
  ],
  description: "Stop a listener",
  category: CCListeners
)
