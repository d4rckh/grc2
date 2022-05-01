import asyncnet, asyncdispatch

import ../../types

proc execProc*(args: seq[string], server: C2Server) {.async.} =
  for tcpListener in server.tcpListeners:
    tcpListener.running = false
    tcpListener.socket.close()
  quit(0)

let cmd*: Command = Command(
  execProc: execProc,
  name: "exit",
  argsLength: 1,
  usage: @["exit"],
  description: "Exit the C2",
  category: CCNavigation
)