import terminal, base64, strutils, ws, json

import terminaltables

import types, loot

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
  stdout.styledWrite "(", menu, ")", shellColor, " nimc2 ", sign, " " , fgDefault
  stdout.flushFile()

proc infoLog*(msg: string, colorText: bool = true) =
  for line in msg.split("\n"):
    if line != "": 
      stdout.styledWriteLine fgBlue, "[!] ", 
        (if not colorText: fgWhite else: fgBlue), line, fgDefault

proc successLog*(msg: string) =
  for line in msg.split("\n"):
    if line != "": stdout.styledWriteLine fgGreen, "[!] ", line, fgDefault

proc errorLog*(msg: string) =
  for line in msg.split("\n"):
    stdout.styledWriteLine fgRed, "[!] ", line, fgDefault

proc cConnected*(client: C2Client) =
  client.createLootDirectories()
  stdout.styledWriteLine fgGreen, "[+] ", $client, " connected", fgDefault
  prompt(client.server)

proc cDisconnected*(client: C2Client, reason: string = "client died") =
  for wsConnection in client.server.wsConnections:
    if wsConnection.readyState == Open:
      discard ws.send(wsConnection, $(%*{
        "event": "clientdisconnect",
        "data": %client
      }))
  stdout.styledWriteLine fgRed, "[-] ", $client, " disconnected", fgWhite, " (", reason, ")"
  prompt(client.server)

proc logClientOutput*(client: C2Client, category: string, b64: string) =
  for line in decode(b64).split("\n"):
    if not ( line == "" ): 
      stdout.styledWriteLine fgGreen, "[=] [Client: ", $client.id, "] ", "[", category, "] ", fgWhite, line

proc printTable*(data: JsonNode) =
  var headers: seq[string] = @[]
  for line in data:
    for key, _ in pairs(line):
      if not (key in headers): headers.add key
  var t = newTerminalTable()
  t.tableWidth = 0
  t.separateRows = false
  t.setHeaders(headers)
  for line in data:
    var row: seq[string] = @[]
    for header in headers:
      if line{header}.isNil:
        row.add "-"
        continue
      let jCell = line[header]

      if jCell.kind == JString: row.add line[header].getStr("-")
      elif jCell.kind == JInt: row.add $line[header].getInt(0)  
      else: row.add "-"
    t.addRow row
  stdout.write t.render()

proc printObject*(data: JsonNode) =
  for key, val in pairs(data):
    stdout.styledWrite fgGreen, key, fgWhite, ": "
    case val.kind:
      of JString:
        stdout.write val.getStr("-")
        stdout.writeLine ""
      of JInt: 
        stdout.write val.getInt(0)
        stdout.writeLine ""
      of JBool:
        stdout.write val.getBool(false)  
        stdout.writeLine ""
      of JNull:
        stdout.write "null"  
        stdout.writeLine ""
      of JFloat:
        stdout.write val.getFloat(0)
        stdout.writeLine ""
      of JObject:
        stdout.writeLine ""
        printObject(val)
      of JArray:
        stdout.writeLine ""
        printTable(val)
