import asyncnet, asyncdispatch, tables

import ../../types

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
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