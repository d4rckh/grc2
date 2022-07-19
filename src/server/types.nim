import std/[
  asyncfutures, 
  asyncnet, 
  json, 
  asyncdispatch, 
  tables, 
  jsonutils, 
  times
]

import ws

type
  TaskStatus* = enum
    TaskCreated = "created", 
    TaskCompleted = "completed", 
    TaskNotCompleted = "pending", 
    TaskCompletedWithError = "completederror", 
    TaskCancelled = "cancelled"

  PreparationSubject* = enum
    PSListener

  CliMode* = enum
    MainMode, ClientInteractMode, ShellMode, PreparationMode

  OSType* = enum
    WindowsOS = "windows", LinuxOS = "linux", UnknownOS = "unknown"

type
  CommandCategory* = enum
    CCNavigation,
    CCClientInteraction,
    CCTasks,
    CCListeners,
    CCImplants

type 
  LinuxVersionInfo* = ref object 
    kernelVersion*: string

type 
  WindowsVersionInfo* = ref object 
    majorVersion*: int
    minorVersion*: int
    buildNumber*: int

type 
  TokenIntegrityLevel* = ref object 
    sid*: string

type TokenInformation* = ref object
  integrityLevel*: TokenIntegrityLevel
  groups*: seq[tuple[name, sid, domain: string]] 

type
  C2Server* = ref object
    clients*: seq[C2Client]
    cli*: C2Cli
    configuration*: Table[string, string]
    # listeners
    # tcpListeners*: seq[TCPListener]
    listeners*: seq[ListenerInstance]
    wsConnections*: seq[WebSocket]
    teamserverClients*: seq[AsyncSocket]
    wsMessages*: seq[string]
    tasks*: seq[Task]
    osType*: OSType

  C2Client* = ref object
    hash*: string
    id*: int
    connected*: bool
    tokenInformation*: TokenInformation
    pid*: int
    pname*: string
    loaded*: bool
    isAdmin*: bool
    hostname*: string
    username*: string
    lastCheckin*: DateTime
    ipAddress*: string
    osType*: OSType
    server*: C2Server
    processes*: seq[tuple[name: string, id: int]]
    windowsVersionInfo*: WindowsVersionInfo
    linuxVersionInfo*: LinuxVersionInfo

  C2Cli* = ref object
    handlingClient*: seq[C2Client]
    mode*: CliMode
    initialized*: bool
    interactive*: bool
    commands*: seq[Command]
    preparing*: PreparationSubject
    lastCommand*: string

  Task* = ref object
    client*: C2Client
    id*: int
    action*: string
    status*: TaskStatus
    arguments*: JsonNode
    future*: ref Future[void]
    output*: JsonNode

  RawTask* = ref object
    clientHash*: string
    clientId*: int
    id*: int
    action*: string
    status*: TaskStatus
    arguments*: JsonNode
    output*: JsonNode
 
  Command* = ref object
    name*: string
    argsLength*: int
    usage*: seq[string]
    aliases*: seq[string]
    execProc*: proc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.}
    cliMode*: seq[CliMode]
    category*: CommandCategory
    description*: string
    requiresConnectedClient*: bool

  # TCP Listener

  ListenerInstance* = ref object
    title*: string
    connectedClients*: seq[C2Client]
    id*: int
    running*: bool
    ipAddress*: string
    port*: Port
    config*: Table[string, string]
    listenerType*: string
    stopProc*: proc() 

  Listener* = ref object
    name*: string
    startProc*: proc(
      server: C2Server, instance: ListenerInstance
    ) {.nimcall async.}

  TCPSocket* = ref object
    socket*: AsyncSocket
    tcpListener*: TCPListener
    netAddr*: string
    id*: int

  TCPListener* = ref object
    socket*: AsyncSocket
    port*: int
    listeningIP*: string
    id*: int
    sockets*: seq[TCPSocket]
    running*: bool

# proc getTcpSocket*(client: C2Client): TCPSocket =
#   for tcpListener in client.server.tcpListeners:
#     var clientSocket: TCPSocket
#     for tcpSocket in tcpListener.sockets:
#       if tcpSocket.id == client.id:
#         clientSocket = tcpSocket
#     if clientSocket.isNil():
#       return nil
#     else:
#       return clientSocket
#   return nil

proc `$`*(l: ListenerInstance): string =
  l.title & " (" & l.listenerType & ")"

proc `$`*(tcpListener: TCPListener): string =
  "TCP:" & $tcpListener.id & " (" & $tcpListener.listeningIP & ":" & $tcpListener.port & ")"

# proc `$`*(osType: OSType): string =
#   case osType:
#     of UnknownOS:
#       "unknown"
#     of WindowsOS:
#       "windows"
#     of LinuxOS:
#       "linux"

proc `$`*(windowsVerion: WindowsVersionInfo): string =
  $windowsVerion.majorVersion & "." & $windowsVerion.minorVersion & " (build: " & $windowsVerion.buildNumber & ")"

proc `@`*(tcpListener: TCPListener): string =
  $tcpListener

proc `$`*(client: C2Client): string =
#   let tcpSocket: TCPSocket = getTcpSocket(client)
#   if tcpSocket.isNil():
#     return $client.id
  if not client.loaded:
    client.ipAddress & "(" & $client.id & ")"
  else:
    client.username & "@" & client.hostname & "(" & $client.id & ")"

# proc `$`*(taskStatus: TaskStatus): string = 
#   case taskStatus:
#     of TaskCompleted: "completed"
#     of TaskNotCompleted: "pending"
#     of TaskCreated: "created"
#     of TaskCompletedWithError: "completederror"
#     of TaskCancelled: "cancelled"

proc `$`*(integrityLevel: TokenIntegrityLevel): string =
  case integrityLevel.sid:
    of "S-1-16-0":
      return "Untrusted Mandatory Level"
    of "S-1-16-4096":
      return "Low Mandatory Level"
    of "S-1-16-8192":
      return "Medium Mandatory Level"
    of "S-1-16-8448":
      return "Medium Plus Mandatory Level"
    of "S-1-16-12288":
      return "High Mandatory Level"
    of "S-1-16-16384":
      return "System Mandatory Level"
    of "S-1-16-20480":
      return "Protected Process Mandatory Level"
    of "S-1-16-28672":
      return "Secure Process Mandatory Level"

proc `@`*(client: C2Client): string =
  let durCheckin: Duration = now() - client.lastCheckin
  if not client.loaded:
    $client
  else:
    $client & "\n\t" & 
      "IP: " & client.ipAddress & "\n\t" &
      "Username: " & client.username & "\n\t" &
      "Last Checkin: " & $durCheckin & " ago\n\t" &
      "Process PID: " & $client.pid & " ago\n\t" &
      "Process Path: " & client.pname & " ago\n\t" &
      "Processs Integrity: " & $client.tokenInformation.integrityLevel & "\n\t" &
      "Running as admin: " & $client.isAdmin & "\n\t" &
      "OS: " & $client.osType & (
        case client.osType:
        of LinuxOS: "\n\tKernel Version: " & client.linuxVersionInfo.kernelVersion
        of WindowsOS: "\n\tWindows Version: " & $client.windowsVersionInfo
        else: ""
      )

proc `%`*(client: C2Client): JsonNode =
  return %*{
    "id": client.id,
    "ipAddress": client.ipAddress,
    "hostname": client.hostname,
    "username": client.username,
    "osType": client.osType,
    "windowsVersionInfo": client.windowsVersionInfo,
    "linuxVersionInfo": client.linuxVersionInfo,
    "connected": client.connected,
    "initialized": client.loaded
  }

proc `%`*(task: Task): JsonNode =
  return %*{
    "client": task.client.id,
    "id": task.id,
    "action": task.action,
    "status": $task.status,
    "arguments": toJson task.arguments,
    "output": task.output
  }

proc `%`*(tcpListener: TCPListener): JsonNode =
  return %*{
    "id": tcpListener.id,
    "listeningIP": tcpListener.listeningIP,
    "port": tcpListener.port
  }

proc `$`*(task: Task): string =
  var x = task.action & " ["

  case task.status:
    of TaskCompleted:
      x &= "Completed]"
    of TaskCreated:
      x &= "Created]"
    of TaskNotCompleted:
      x &= "Pending]"
    of TaskCompletedWithError:
      x &= "Completed w/ Error]"
    of TaskCancelled:
      x &= "Cancelled]"
  
  x &= " (" & $task.id & ")"

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

proc markAsCompleted*(task: Task, response: JsonNode = %*{}) = 
  task.output = response
  if response == %*{}:
    task.status = TaskCancelled
  elif response["error"].getStr() == "":
    task.status = TaskCompleted
  else:
    task.status = TaskCompletedWithError
  if not task.future[].isNil():
    task.future[].complete()
    task.future[] = nil

proc getRawTask*(task: Task): RawTask =
  RawTask(
      clientHash: task.client.hash,
      clientId: task.client.id,
      id: task.id,
      action: task.action,
      status: task.status,
      arguments: task.arguments,
      output: task.output
    )

proc getRawTasks*(tasks: seq[Task]): seq[RawTask] =
  for task in tasks:
    result.add getRawTask(task)
