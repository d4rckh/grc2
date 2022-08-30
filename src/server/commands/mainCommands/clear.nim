import ../prelude

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  stdout.eraseScreen()
  setCursorPos(0,0)

let cmd*: Command = Command(
  execProc: execProc,
  name: "clear",
  aliases: @["cls"],
  argsLength: 0,
  usage: @["clear"],
  description: "Clean the screen",
  category: CCNavigation
)