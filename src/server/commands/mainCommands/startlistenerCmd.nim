import asyncdispatch, strutils, asyncfutures, parseopt

import ../../types, ../../listeners/tcp, ../../logging

proc execProc*(args: seq[string], server: C2Server) {.async.} =

  var listenerType: string = ""

  # for listeners that require an IP and port
  var ip: string = ""
  var port: string = ""

  var slArgs: seq[string] = args
  slArgs[0] = ""

  var p = initOptParser(slArgs.join(" "))

  while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      if p.val != "":
        case p.key:
        of "ip", "i": ip = p.val
        of "port", "p": port = p.val
    of cmdArgument:
      listenerType = p.key

  if listenerType == "":
    errorLog "you must specify a listener type, supported: tcp (check 'help startlistener' for more info)"
    return

  case listenerType.toLower():
  of "tcp":
      if ip != "" and port != "":
        asyncCheck server.createNewTcpListener(parseInt(port), ip)
      else:
        errorLog "--ip and --port flags are required for this listener type"

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
