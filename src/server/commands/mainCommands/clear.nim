import std/[
  asyncdispatch, 
  tables, 
  terminal
]

import ../../types

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  stdout.eraseScreen()

let cmd*: Command = Command(
  execProc: execProc,
  name: "clear",
  aliases: @["cls"],
  argsLength: 0,
  usage: @["clear"],
  description: "Clean the screen",
  category: CCNavigation
)