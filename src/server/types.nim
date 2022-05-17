import asyncfutures, asyncnet, json, asyncdispatch, tables

type
  TaskStatus* = enum
    TaskCompleted, TaskNotCompleted, TaskCompletedWithError, TaskCancelled

  PreparationSubject* = enum
    PSListener

  CliMode* = enum
    MainMode, ClientInteractMode, ShellMode, PreparationMode

  OSType* = enum
    WindowsOS, LinuxOS, UnknownOS

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
    # listeners
    tcpListeners*: seq[TCPListener]
    tasks*: seq[Task]
    osType*: OSType

  C2Client* = ref object
    # socket*: AsyncSocket
    listenerType*: string
    listenerId*: int
    id*: int
    connected*: bool
    tokenInformation*: TokenInformation
    # shit
    loaded*: bool
    isAdmin*: bool
    hostname*: string
    username*: string
    ipAddress*: string
    osType*: OSType
    server*: C2Server
    processes*: seq[tuple[name: string, id: int]]
    windowsVersionInfo*: WindowsVersionInfo
    linuxVersionInfo*: LinuxVersionInfo

  C2Cli* = ref object
    handlingClient*: C2Client
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

proc `$`*(osType: OSType): string =
  case osType:
    of UnknownOS:
      "unknown"
    of WindowsOS:
      "windows"
    of LinuxOS:
      "linux"

proc `$`*(windowsVerion: WindowsVersionInfo): string =
  $windowsVerion.majorVersion & "." & $windowsVerion.minorVersion & " (build: " & $windowsVerion.buildNumber & ")"

proc `@`*(tcpListener: TCPListener): string =
  $tcpListener

proc `$`*(client: C2Client): string =
  let tcpSocket: TCPSocket = getTcpSocket(client)
  if not client.loaded:
    $client.id & "(" & tcpSocket.netAddr & ")"
  else:
    $client.id & "(" & tcpSocket.netAddr & ")(" & client.hostname & ")"

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
  if not client.loaded:
    $client & "(" & (if client.connected: "alive" else: "dead") & ")"
  else:
    $client & " (" & (if client.connected: "alive" else: "dead") & ")\n\t" & 
      "IP: " & client.ipAddress & "\n\t" &
      "Username: " & client.username & "\n\t" &
      "Processs Integrity: " & $client.tokenInformation.integrityLevel & "\n\t" &
      "Running as admin: " & $client.isAdmin & "\n\t" &
      "OS: " & $client.osType & (
        case client.osType:
        of LinuxOS: "\n\tKernel Version: " & client.linuxVersionInfo.kernelVersion
        of WindowsOS: "\n\tWindows Version: " & $client.windowsVersionInfo
        else: ""
      )

proc `$`*(task: Task): string =
  var x = "(" & $task.id & ")" & task.action & " ["

  case task.status:
    of TaskCompleted:
      x &= "Completed]"
    of TaskNotCompleted:
      x &= "Pending]"
    of TaskCompletedWithError:
      x &= "Completed w/ Error]"
    of TaskCancelled:
      x &= "Cancelled]"

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
  if response == %*{}:
    task.status = TaskCancelled
  elif response["error"].getStr() == "":
    task.status = TaskCompleted
  else:
    task.status = TaskCompletedWithError
  if not task.future[].isNil():
    task.future[].complete()
    task.future[] = nil