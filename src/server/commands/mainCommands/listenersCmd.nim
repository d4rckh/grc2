import asyncdispatch, tables

import ../../types
import ../../logging

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  for tcpListener in server.tcpListeners:
    infoLog @tcpListener
    if "c" in flags or "clients" in flags:
      for client in server.clients:
        if client.listenerType == "tcp" and client.listenerId == tcpListener.id and client.connected:
          infoLog "\t<- " & $client
  infoLog $len(server.tcpListeners) & " listeners"

let cmd*: Command = Command(
  execProc: execProc,
  name: "listeners",
  aliases: @["l"],
  argsLength: 0,
  usage: @[
    "listeners",
    "listeners -c/--clients"
  ],
  description: "Print all listeners",
  category: CCListeners
)