import ../prelude

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  for client in server.cli.handlingClient:  

    let task = await client.sendClientTask("tokinfo")
    if not task.isNil(): 
      await task.awaitResponse()
      if not task.isError(): printObject(parseJson(task.output.data))
      else:
        errorLog task.output.error

let cmd*: Command = Command(
  execProc: execProc,
  name: "tokeninfo",
  argsLength: 0,
  usage: @["tokeninfo"],
  cliMode: @[ClientInteractMode],
  description: "Get info about own process windows token",
  category: CCClientInteraction,
  requiresConnectedClient: true
)