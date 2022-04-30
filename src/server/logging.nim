import terminal, base64, strutils

import types

proc prompt*(client: C2Client, cmdMode: bool, server: C2Server) = 
  var menu: string = "main"
  if not client.isNil():
    if not client.loaded:
      menu = "client:" & $client.id
    else:
      menu = client.username & (if client.isAdmin: "*" else: "") & "@" & client.hostname
  stdout.styledWrite fgDefault, "(", menu ,")", fgRed, " nimc2 " & (if cmdMode: "$" else: ">") & " " , fgDefault

proc infoLog*(msg: string) =
  stdout.styledWriteLine fgBlue, "[!] ", msg, fgDefault

proc errorLog*(msg: string) =
  for line in msg.split("\n"):
    stdout.styledWriteLine fgRed, "[!] ", line, fgDefault

proc cConnected*(client: C2Client) =
  stdout.styledWriteLine fgGreen, "[+] ", $client, " connected", fgDefault

proc cDisconnected*(client: C2Client) =
  stdout.styledWriteLine fgRed, "[-] ", $client, " disconnected", fgDefault

proc logClientOutput*(client: C2Client, category: string, b64: string) =
  for line in decode(b64).split("\n"):
    if not ( line == "" ): 
      stdout.styledWriteLine fgGreen, "[=] [Client: ", $client.id, "] ", "[", category, "] ", fgDefault, line