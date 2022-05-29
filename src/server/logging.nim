import terminal, base64, strutils, ws, json

import types

proc genClientSummary(client: seq[C2Client]): string =
  var menu = "client:unknown"
  if client.len > 0:
    if client.len == 1:
      if not client[0].loaded:
          menu = "client:" & $(client[0].id)
      else:
          menu = client[0].username & (if client[0].isAdmin: "*" else: "") & "@" & client[0].hostname
    else:
      menu = $client.len & " clients"
  return menu

proc prompt*(server: C2Server) = 
  let cli = server.cli
  
  if not ( server.cli.initialized and server.cli.interactive ): return
  
  let client = server.cli.handlingClient

  var menu: string = "main"
  var sign: string = ">"
  var shellColor = fgRed

  case cli.mode:
  of ClientInteractMode: 
    menu = genClientSummary(client)
    sign = ">"
  of MainMode:
    menu = "main"
    sign = ">"
  of PreparationMode:
    menu = "preparing"
    sign = ">"
  of ShellMode:
    menu = genClientSummary(client)
    sign = (if client.len == 1: ( if client[0].isAdmin: "#" else: "$" ) else: "?")
  stdout.styledWrite "(", menu ,")", shellColor, " nimc2 " & sign & " " , fgDefault
  stdout.flushFile()

proc infoLog*(msg: string) =
  stdout.styledWriteLine fgBlue, "[!] ", msg, fgDefault

proc errorLog*(msg: string) =
  for line in msg.split("\n"):
    stdout.styledWriteLine fgRed, "[!] ", line, fgDefault

proc cConnected*(client: C2Client)  =
  for wsConnection in client.server.wsConnections:
    if wsConnection.readyState == Open:
      discard ws.send(wsConnection, $(%*{
        "event": "clientconnect",
        "data": %client
      }))

  stdout.styledWriteLine fgGreen, "[+] ", $client, " connected", fgDefault
  prompt(client.server)

proc cDisconnected*(client: C2Client, reason: string = "client died") =
  for wsConnection in client.server.wsConnections:
    if wsConnection.readyState == Open:
      discard ws.send(wsConnection, $(%*{
        "event": "clientdisconnect",
        "data": %client
      }))
  stdout.styledWriteLine fgRed, "[-] ", $client, " disconnected", fgDefault, " (", reason, ")"
  prompt(client.server)

proc logClientOutput*(client: C2Client, category: string, b64: string) =
  for line in decode(b64).split("\n"):
    if not ( line == "" ): 
      stdout.styledWriteLine fgGreen, "[=] [Client: ", $client.id, "] ", "[", category, "] ", fgWhite, line