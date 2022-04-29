import terminal, base64, strutils

import types

proc prompt*(client: C2Client, server: C2Server) = 
  var menu: string = "main"
  if not client.isNil():
    if not client.loaded:
        menu = "client:" & $client.id
    else:
        menu = client.username & (if client.isAdmin: "*" else: "") & "@" & client.hostname
  stdout.styledWrite "(", menu ,")", fgRed, " nimc2 > " , fgWhite

proc infoLog*(msg: string) =
    stdout.styledWriteLine fgBlue, "[!] ", msg, fgWhite

proc errorLog*(msg: string) =
    for line in msg.split("\n"):
        stdout.styledWriteLine fgRed, "[!] ", line, fgWhite

proc cConnected*(client: C2Client) =
    stdout.styledWriteLine fgGreen, "[+] ", $client, " connected", fgWhite

proc cDisconnected*(client: C2Client) =
    stdout.styledWriteLine fgRed, "[-] ", $client, " disconnected", fgWhite

proc logClientOutput*(client: C2Client, category: string, b64: string) =
    for line in decode(b64).split("\n"):
        if not ( line == "" ): 
            stdout.styledWriteLine fgGreen, "[=] [Client: ", $client.id, "] ", "[", category, "] ", fgWhite, line