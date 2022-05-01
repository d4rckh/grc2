import asyncdispatch

import ../../types
import ../../logging

proc execProc(args: seq[string], server: C2Server) {.async.} =
  for tcpListener in server.tcpListeners:
    infoLog @tcpListener
    for client in server.clients:
      if client.listenerType == "tcp" and client.listenerId == tcpListener.id and client.connected:
        infoLog "\t<- " & $client
  infoLog $len(server.tcpListeners) & " listeners"

let cmd*: Command = Command(
  execProc: execProc,
  name: "clientlisteners",
  argsLength: 1,
  usage: @["clientlisteners"],
  description: "View listeners along with the clients connected to them",
  category: CCListeners
)