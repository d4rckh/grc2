import asyncfutures, asyncnet, json, asyncdispatch

type
  TaskStatus* = enum
    TaskCompleted, TaskNotCompleted, TaskCompletedWithError

type
  CliMode* = enum
    MainMode, ClientInteractMode, ShellMode, PreparationMode

type
  CommandCategory* = enum
    CCNavigation,
    CCClientInteraction,
    CCTasks,
    CCListeners,
    CCImplants

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
    status*: TaskStatus
    arguments*: JsonNode
    future*: ref Future[void]

  C2Server* = ref object
    clients*: seq[C2Client]
    cli*: C2Cli
    # listeners
    tcpListeners*: seq[TCPListener]
    tasks*: seq[Task]

  C2Cli* = ref object
    handlingClient*: C2Client
    mode*: CliMode
    initialized*: bool
    commands*: seq[Command]

  Command* = ref object
    name*: string
    argsLength*: int
    usage*: seq[string]
    execProc*: proc(args: seq[string], server: C2Server) {.async.}
    cliMode*: seq[CliMode]
    category*: CommandCategory
    description*: string


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
  "TCP:" & $tcpListener.id & " (" & $tcpListener.listeningIP & ":" & $tcpListener.port & ")"

proc `@`*(tcpListener: TCPListener): string =
  $tcpListener

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

proc `$`*(task: Task): string =
  var x = "(" & $task.id & ")" & task.action & " ["

  case task.status:
    of TaskCompleted:
      x &= "Completed]"
    of TaskNotCompleted:
      x &= "Pending]"
    of TaskCompletedWithError:
      x &= "Completed w/ Error]"

  x

proc `$`*(cc: CommandCategory): string =
  case cc:
  of CCNavigation:
    "Navigation"
  of CCClientInteraction:
    "Client interaction"
  of CCImplants:
    "Implants"
  of CCListeners:
    "Listeners"
  of CCTasks:
    "Tasks"

proc markAsCompleted*(task: Task, response: JsonNode) = 
  if response["error"].getStr() == "":
    task.status = TaskCompleted
  else:
    task.status = TaskCompletedWithError
  if not task.future[].isNil():
    task.future[].complete()
    task.future[] = nil