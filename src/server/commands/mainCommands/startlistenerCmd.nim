import asyncdispatch, strutils, asyncfutures

import ../../types
import ../../listeners/tcp

proc execProc*(args: seq[string], server: C2Server) {.async.} =
  let argsn = len(args)
  if argsn >= 2:
    if args[1].toLower() == "tcp":
      if argsn >= 4:
        asyncCheck server.createNewTcpListener(parseInt(args[3]), args[2])
      else:
        echo "Bad usage, correct usage: startlistener TCP (ip) (port)"
  else:
    echo "You need to specify the type of listener you wanna start, supported: TCP"

let cmd*: Command = Command(
  execProc: execProc,
  name: "startlistener",
  argsLength: 2,
  usage: @[
    "startlistener [listenerType] [ip] [port]",
  ],
  description: "Start a new listener",
  category: CCListeners
)