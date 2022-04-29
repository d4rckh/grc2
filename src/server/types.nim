import asyncfutures, asyncnet


type
  TCPSocket* = ref object
    socket*: AsyncSocket
    netAddr*: string
    id*: int

  TCPListener* = ref object
    socket*: AsyncSocket
    port*: int
    listeningIP*: string
    id*: int
    sockets*: seq[TCPSocket]
    running*: bool

type
  C2Client* = ref object
    # socket*: AsyncSocket
    listenerType*: string
    listenerId*: int
    id*: int
    connected*: bool
    # shit
    loaded*: bool
    isAdmin*: bool
    hostname*: string
    username*: string
    server*: C2Server

  Task* = ref object
    client*: C2Client
    id*: int
    action*: string
    arguments*: seq[string]

  C2Server* = ref object
    clients*: seq[C2Client]
    # listeners
    tcpListeners*: seq[TCPListener]
    tasks*: seq[Task]
    # futures
    clRespFuture*: ref Future[void]
    svStartFuture*: ref Future[void]

proc getTcpSocket*(client: C2Client): TCPSocket =
  if client.listenerType == "tcp":
    let tcpSockets = client.server.tcpListeners[client.listenerId].sockets
    var clientSocket: TCPSocket
    for tcpSocket in tcpSockets:
      if tcpSocket.id == client.id:
        clientSocket = tcpSocket
    if clientSocket.isNil():
      return nil
    else:
      return clientSocket
  return nil

proc `$`*(tcpListener: TCPListener): string =
  "TCP" & $tcpListener.id & "(" & $tcpListener.listeningIP & ":" & $tcpListener.port & ")"

proc `@`*(tcpListener: TCPListener): string =
  "TCP" & $tcpListener.id & "(" & $tcpListener.listeningIP & ":" & $tcpListener.port & ") <- " & $len(tcpListener.sockets) & " connected sockets"

proc `$`*(client: C2Client): string =
  let tcpSocket: TCPSocket = getTcpSocket(client)
  if not client.loaded:
    $client.id & "(" & tcpSocket.netAddr & ")"
  else:
    $client.id & "(" & tcpSocket.netAddr & ")(" & client.hostname & ")"

proc `@`*(client: C2Client): string =
  if not client.loaded:
    $client & "(" & (if client.connected: "alive" else: "dead") & ")"
  else:
    $client & " (" & (if client.connected: "alive" else: "dead") & ") INITIALIZED\n\t" & 
      "Username: " & client.username & "\n\t" &
      "Is Admin: " & $client.isAdmin
