import std/[
  asyncfutures, 
  asyncnet, 
  json, 
  asyncdispatch, 
  tables, 
  jsonutils,
  strutils, 
  times
]

import ws

type 
  Template* = object 
    name*: string 
    build*: proc(shellcode: string): string
    isBinary*: bool
    outExtension*: string

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
  TaskOutput* = ref object
    data*: string
    error*: string

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
    debug*: bool

  C2Client* = ref object
    hash*: string
    id*: string
    connected*: bool
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
    windowsVersionInfo*: WindowsVersionInfo

  C2Cli* = ref object
    handlingClient*: seq[C2Client]
    mode*: CliMode
    initialized*: bool
    interactive*: bool
    commands*: seq[Command]
    preparing*: PreparationSubject
    lastCommand*: string
    waitingForOutput*: bool

  Task* = ref object
    client*: C2Client
    id*: int
    action*: string
    status*: TaskStatus
    arguments*: JsonNode
    future*: ref Future[void]
    output*: TaskOutput
 
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

proc `$`*(windowsVerion: WindowsVersionInfo): string =
  $windowsVerion.majorVersion & "." & $windowsVerion.minorVersion & " (build: " & $windowsVerion.buildNumber & ")"

proc `$`*(client: C2Client): string =
  if not client.loaded:
    client.ipAddress & "(" & $client.id & ")"
  else:
    client.username & "@" & client.hostname & "(" & $client.id & ")"

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

proc `$`*(l: ListenerInstance): string =
  l.title & " (" & l.listenerType & ")"

proc get_last_checkin*(client: C2Client): string =
  if client.lastCheckin.isInitialized:
    result = $(now() - client.lastCheckin)
    result = result.split(",")[0]
  else:
    result = "not check in's"

proc `@`*(client: C2Client): string =
  if not client.loaded:
    $client
  else:
    $client & "\n\t" & 
      "IP: " & client.ipAddress & "\n\t" &
      "Username: " & client.username & "\n\t" &
      "Last Checkin: " & client.get_last_checkin() & "\n\t" &
      "Process PID: " & $client.pid & "\n\t" &
      "Process Path: " & client.pname & "\n\t" &
      (if client.osType != WindowsOS: "Running as admin: " & $client.isAdmin & "\n\t" else: "") &
      "OS: " & $client.osType & (
        case client.osType:
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

