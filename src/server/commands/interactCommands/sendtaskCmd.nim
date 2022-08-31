import ../prelude

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  for client in server.cli.handlingClient:
    let task = await client.sendClientTask(args[0], toJson args[1..(args.len-1)])
    if not task.isNil(): 
      await task.awaitResponse()
      echo "response: " & task.output.data

let cmd*: Command = Command(
  execProc: execProc,
  name: "sendtask",
  argsLength: 0,
  usage: @["sendtask \"[taskname]\" \"[param1]\" \"[param2]\" \"[..]\" "],
  cliMode: @[ClientInteractMode],
  description: "send custom task",
  category: CCClientInteraction,
  requiresConnectedClient: true
)