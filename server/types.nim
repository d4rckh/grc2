import asyncnet, asyncfutures

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

  Client* = ref object
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

  C2Server* = ref object
    clients*: seq[Client]
    # listeners
    tcpListeners*: seq[TCPListener]
    # futures
    clRespFuture*: ref Future[void]
    svStartFuture*: ref Future[void]

proc getTcpSocket*(client: Client): TCPSocket =
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

proc `$`*(client: Client): string =
  let tcpSocket: TCPSocket = getTcpSocket(client)
  if not client.loaded:
    $client.id & "(" & tcpSocket.netAddr & ")"
  else:
    $client.id & "(" & tcpSocket.netAddr & ")(" & client.hostname & ")"

proc `$`*(tcpListener: TCPListener): string =
  "TCP(" & $tcpListener.listeningIP & ":" & $tcpListener.port & ")"

# detailed info about something

proc `@`*(tcpListener: TCPListener): string =
  "TCP(" & $tcpListener.listeningIP & ":" & $tcpListener.port & ") <- " & $len(tcpListener.sockets) & " connected sockets"

proc `@`*(client: Client): string =
  if not client.loaded:
    $client & "(" & (if client.connected: "alive" else: "dead") & ")"
  else:
    $client & " (" & (if client.connected: "alive" else: "dead") & ") INITIALIZED\n\t" & 
      "Username: " & client.username & "\n\t" &
      "Is Admin: " & $client.isAdmin