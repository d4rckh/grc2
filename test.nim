import net

let client: Socket = newSocket()
client.connect("127.0.0.1", Port(12345))

proc receiveCommands(client: Socket) =
    
    while true:
        let line = client.recvLine()
        
        if line.len == 0:
            echo "server down"
            quit(0)
receiveCommands(client)
  
client.close()
