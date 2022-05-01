import asyncdispatch

import ../../types
import ../../logging

proc execProc*(args: seq[string], server: C2Server) {.async.} =
  for tcpListener in server.tcpListeners:
    infoLog @tcpListener
  infoLog $len(server.tcpListeners) & " listeners"

let cmd*: Command = Command(
  execProc: execProc,
  name: "listeners",
  argsLength: 1,
  usage: @[
    "listeners",
  ],
  description: "Print all listeners",
  category: CCListeners
)