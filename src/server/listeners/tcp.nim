import asyncdispatch, asyncnet, asyncfutures, strutils, json, base64, ws

import ../types, ../logging, ../processMessage

proc processMessages(server: C2Server, tcpSocket: TCPSocket, client: C2Client) {.async.} =
  
  var msgS: string = ""
  var linesRecv: int = 0

  while client.connected:
    let line = await tcpSocket.socket.recvLine()

    if line.len == 0:
      client.connected = false
      tcpSocket.socket.close()
      cDisconnected(client, "client died")
      continue

    inc linesRecv

    if linesRecv == 3:
      client.connected = false
      tcpSocket.socket.close()
      cDisconnected(client, "too much data sent")
      for task in server.tasks:
        if task.client == client:
          task.markAsCompleted(%*{ "error": "client sent too much data" })
      continue

    msgS &= line

    var response: JsonNode
    try:
      response = parseJson(decode(msgS))
    except JsonParsingError:
      continue

    msgS = ""
    linesRecv = 0 

    discard processMessage(client, response)

proc createNewTcpListener*(server: C2Server, port = 12345, ip = "127.0.0.1") {.async.} =
  let id = len(server.tcpListeners)
  
  let tcpServer = TCPListener(
      sockets: @[], 
      port: port,
      listeningIP: ip,
      id: id, 
      socket: newAsyncSocket(),
      running: true
    )
  try:
    tcpServer.socket.setSockOpt(OptReuseAddr, true)
    tcpServer.socket.bindAddr(port.Port, ip)
    tcpServer.socket.listen()
  except OSError:
    errorLog getCurrentExceptionMsg()
    return
  
  server.tcpListeners.add(tcpServer)
  infoLog "listening on " & tcpServer.listeningIP & ":" & $tcpServer.port & " using a tcp socket"
  
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
        server: server,
        ipAddress: netAddr
      )
      tcpSocket = TCPSocket(
        socket: clientSocket,
        id: client.id,
        netAddr: netAddr
      )

    server.clients.add(client)
    tcpServer.sockets.add(tcpSocket)

    asyncCheck processMessages(server, tcpSocket, client)

  infoLog $tcpServer & " stopped"