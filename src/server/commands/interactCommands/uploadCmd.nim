import ../prelude

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  for client in server.cli.handlingClient:
    var openFile = await client.sendClientTask("fsopenfile", @[ "w", args[0] ])
    if openFile.isNil():
      errorLog "Server error opening file"
      return  
    await openFile.awaitResponse()
    let openFileTlv = initParser()
    openFileTlv.setBuffer(cast[seq[byte]](openFile.output.data))
    let fileId = openFileTlv.extractInt32()
    if fileId == -1:
      errorLog "Client error couldn't open file"
      return
    
let cmd*: Command = Command(
  execProc: execProc,
  name: "upload",
  argsLength: 2,
  usage: @["upload [local file] [remote file]"],
  cliMode: @[ClientInteractMode],
  description: "Upload a local file to a remote file",
  category: CCClientInteraction,
  requiresConnectedClient: true
)