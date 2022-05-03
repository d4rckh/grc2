import terminal, base64, strutils

import types

proc prompt*(server: C2Server) = 
  let cli = server.cli
  
  if not ( server.cli.initialized and server.cli.interactive ): return
  
  let client = server.cli.handlingClient

  var menu: string = "main"
  var sign: string = ">"
  var shellColor = fgRed

  case cli.mode:
  of ClientInteractMode: 
    if not client.isNil():
      if not client.loaded:
        menu = "client:" & $(client.id)
      else:
        menu = client.username & (if client.isAdmin: "*" else: "") & "@" & client.hostname
    else:
      menu = "client:unknown"
    sign = ">"
  of MainMode:
    menu = "main"
    sign = ">"
  of PreparationMode:
    menu = "preparing"
    sign = ">"
  of ShellMode:
    if not client.isNil():
      if not client.loaded:
        menu = "client:" & $(client.id)
      else:
        menu = client.username & (if client.isAdmin: "*" else: "") & "@" & client.hostname
    else:
      menu = "client:unknown"
    sign = (if client.isAdmin: "#" else: "$")
  stdout.styledWrite fgDefault, "(", menu ,")", shellColor, " nimc2 " & sign & " " , fgDefault
  stdout.flushFile()

proc infoLog*(msg: string) =
  stdout.styledWriteLine fgBlue, "[!] ", msg, fgDefault

proc errorLog*(msg: string) =
  for line in msg.split("\n"):
    stdout.styledWriteLine fgRed, "[!] ", line, fgDefault

proc cConnected*(client: C2Client) =
  stdout.styledWriteLine fgGreen, "[+] ", $client, " connected", fgDefault
  prompt(client.server)

proc cDisconnected*(client: C2Client, reason: string = "client died") =
  stdout.styledWriteLine fgRed, "[-] ", $client, " disconnected", fgDefault, " (", reason, ")"
  prompt(client.server)

proc logClientOutput*(client: C2Client, category: string, b64: string) =
  for line in decode(b64).split("\n"):
    if not ( line == "" ): 
      stdout.styledWriteLine fgGreen, "[=] [Client: ", $client.id, "] ", "[", category, "] ", fgDefault, line