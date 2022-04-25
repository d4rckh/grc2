import asyncdispatch, asyncnet, threadpool
import strutils, terminal

import asyncdispatch, asynchttpserver, ws

import types, logging

proc newServer(): C2Server =
  C2Server(socket: newAsyncSocket(), clients: @[])

var server = newServer()
infoLog "server initialized"

proc processMessages(server: C2Server, client: Client) {.async.} =
  while true:
    let line = await client.socket.recvLine()

    if line.len == 0:
      
      cDisconnected(client)
      
      client.connected = false
      client.socket.close()
      return
    if line == "connect":
      await client.socket.send("hi\r\n")
    if line == "pong":
      echo "pong from " & $client
    if line.startsWith("INFO:"):
      let hostname = line.split(":")[1]
      server.clients[client.id].loaded = true
      server.clients[client.id].hostname = hostname
    # for c in server.clients:
    #   if c.id != client.id and c.connected:
    #     await c.socket.send(line & "\c\l")

proc acceptSocketClients(port = 12345) {.async.} =
  server.socket.bindAddr(port.Port)
  server.socket.listen()
  
  infoLog "listening on localhost:" & intToStr(port)
  
  while true:
    let (netAddr, clientSocket) = await server.socket.acceptAddr()
    
    let client = Client(
      socket: clientSocket,
      netAddr: netAddr,
      id: server.clients.len,
      connected: true,
      loaded: false,
      hostname: "placeholder"
    )

    cConnected(client)

    server.clients.add(client)
    asyncCheck processMessages(server, client)

proc prompt(handlingClient: int, server: C2Server) = 
  var menu: string = "main"
  if handlingClient > -1:
    menu = "client:"&intToStr(handlingClient)
  stdout.styledWrite fgBlue, "(", menu ,")", fgRed, " nimc2 > " , fgWhite

proc procStdin() {.async.} =
  var handlingClient: int = -1

  prompt(handlingClient, server)
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
      if cmd.startsWith("ping"):
        for client in server.clients:
          if client.id == parseInt(cmd.split(" ")[1]):
            echo "pinging " & $client
            await client.socket.send("ping\r\n")
      if cmd.startsWith("info"):
        for client in server.clients:
          if client.id == handlingClient:
            echo $client
      if cmd == "back":
        handlingClient = -1

      prompt(handlingClient, server)
      messageFlowVar = spawn stdin.readLine()
      
    await asyncdispatch.sleepAsync(100)

# var connections = newSeq[WebSocket]()

# proc cb(req: Request) {.async, gcsafe.} =
#   if req.url.path == "/ws":
#     try:
#       var ws = await newWebSocket(req)
#       connections.add ws
#       await ws.send("Welcome to simple chat server")
#       while ws.readyState == Open:
#         let packet = await ws.receiveStrPacket()
#         echo "Received packet: " & packet
#         for other in connections:
#           if other.readyState == Open:
#             asyncCheck other.send(packet)
#     except WebSocketClosedError:
#       echo "Socket closed. "
#     except WebSocketProtocolMismatchError:
#       echo "Socket tried to use an unknown protocol: ", getCurrentExceptionMsg()
#     except WebSocketError:
#       echo "Unexpected socket error: ", getCurrentExceptionMsg()
#   await req.respond(Http200, "Hello World")

# var httpServer = newAsyncHttpServer()


asyncCheck procStdin()
asyncCheck acceptSocketClients()
# asyncCheck httpServer.serve(Port(9001), cb)

runForever()