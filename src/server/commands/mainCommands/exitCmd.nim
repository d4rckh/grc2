import ../prelude

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  quit(0)

let cmd*: Command = Command(
  execProc: execProc,
  name: "exit",
  argsLength: 0,
  usage: @["exit"],
  description: "Exit the C2",
  category: CCNavigation
)