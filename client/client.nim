import net

let client: Socket = newSocket()
client.connect("127.0.0.1", Port(12345))
stdout.writeLine("Client: connected to server on address 127.0.0.1:12345")

proc receiveCommands(client: Socket) =
    client.send("connect\r\n")
    while true:
        let line = client.recvLine()
        if line.len == 0:
            echo "server down"
            quit(0)

receiveCommands(client)
  
client.close()
