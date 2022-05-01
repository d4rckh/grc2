import terminal, asyncdispatch

import ../../types
import ../../logging

proc execProc*(args: seq[string], server: C2Server) {.async.} =
  for client in server.clients:
    if client.connected:
      stdout.styledWriteLine fgGreen, "[+] ", $client, fgWhite
    else:
      stdout.styledWriteLine fgRed, "[-] ", $client, fgWhite
  infoLog $len(server.clients) & " clients currently connected"

let cmd*: Command = Command(
  execProc: execProc,
  name: "clients",
  argsLength: 1,
  usage: @["clients"],
  description: "View clients that were connected and are currently connected",
  category: CCClientInteraction
)