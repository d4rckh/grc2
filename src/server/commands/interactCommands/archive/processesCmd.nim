import ../prelude

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  for client in server.cli.handlingClient:
    
    let task = await client.sendClientTask("processes")
    if task.isNil(): 
      return

    await task.awaitResponse()
    var processes: seq[tuple[id: int32, name: string]]
    
    let p = initParser()
    p.setBuffer(cast[seq[byte]](task.output.data))

    let psCount = p.extractInt32()
    for _ in 1..psCount:
      processes.add (
        id: p.extractInt32(),
        name: p.extractString()
      )

    if args.len < 1: 
      printTable(toJson processes)
      return 

    var filteredProcesses: seq[tuple[id: int32, name: string]]
    for process in processes:
      if not ( args[0].toLowerAscii() in process.name.toLowerAscii() ): continue
      filteredProcesses.add (id: process.id, name: process.name)

    if filteredProcesses.len == 0:
      infoLog "no processes found with name"
      return
    
    printTable(toJson filteredProcesses)

let cmd*: Command = Command(
  execProc: execProc,
  name: "processes",
  argsLength: 0,
  aliases: @["ps"],
  usage: @["processes [optional, search image name]"],
  cliMode: @[ClientInteractMode],
  description: "List processes on target",
  category: CCClientInteraction,
  requiresConnectedClient: true
)