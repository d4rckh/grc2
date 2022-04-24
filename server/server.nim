import asyncdispatch, asyncnet, threadpool
import strutils, terminal

import types, logging

proc newServer(): Server =
  Server(socket: newAsyncSocket(), clients: @[])

proc processMessages(server: Server, client: Client) {.async.} =
  while true:
    let line = await client.socket.recvLine()

    if line.len == 0:
      
      cDisconnected(client)
      
      client.connected = false
      client.socket.close()
      return

    if line == "connect":
      await client.socket.send("hi\r\n")

    for c in server.clients:
      if c.id != client.id and c.connected:
        await c.socket.send(line & "\c\l")

proc loop(server: Server, port = 12345) {.async.} =
  server.socket.bindAddr(port.Port)
  server.socket.listen()
  
  infoLog "listening on localhost:" & intToStr(port)
  
  while true:
    let (netAddr, clientSocket) = await server.socket.acceptAddr()
    
    let client = Client(
      socket: clientSocket,
      netAddr: netAddr,
      id: server.clients.len,
      connected: true
    )

    cConnected(client)

    server.clients.add(client)
    asyncCheck processMessages(server, client)

proc prompt(handlingClient: int, server: Server): string = 
  var p: string = ""
  if handlingClient > -1:
    p &= intToStr(handlingClient) & " "
  p &= "> "
  p

proc procStdin(server: Server) {.async.} =
  var handlingClient: int = -1

  stdout.write prompt(handlingClient, server)
  var messageFlowVar = spawn stdin.readLine()
  while true:
    if messageFlowVar.isReady():
      
      let cmd = ^messageFlowVar

      if cmd == "clients":
        for client in server.clients:
          if client.connected:
            stdout.styledWriteLine fgGreen, "[+] ", $client, " (alive)", fgWhite
          else:
            stdout.styledWriteLine fgRed, "[-] ", $client, " (dead)", fgWhite
      if cmd.startsWith("switch"):
        handlingClient = parseInt(cmd.split(" ")[1])
      if cmd == "back":
        handlingClient = -1

      stdout.write prompt(handlingClient, server)
      messageFlowVar = spawn stdin.readLine()
      
    asyncdispatch.poll()

when isMainModule:
  var server = newServer()
  infoLog "server initialized"
  
  asyncCheck loop(server)
  asyncCheck procStdin(server)