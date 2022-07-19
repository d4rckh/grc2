import std/[
  asyncdispatch, 
  tables, 
  nativesockets
]

import ../../types
import ../../logging

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  for listener in server.listeners:
    infoLog $listener
    echo "- IP: " & listener.ipAddress
    echo "- Port: " & $listener.port
  # for tcpListener in server.tcpListeners:
  #   infoLog @tcpListener
  #   if "c" in flags or "clients" in flags:
  #     for tcpSocket in tcpListener.sockets:
  #       infoLog "\t<- " & $server.clients[tcpSocket.id]
  # infoLog $len(server.tcpListeners) & " listeners"

let cmd*: Command = Command(
  execProc: execProc,
  name: "listeners",
  aliases: @["l"],
  argsLength: 0,
  usage: @[
    "listeners"
  ],
  description: "Print all listeners",
  category: CCListeners
)