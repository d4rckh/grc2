import asyncdispatch

import ../../types

proc execProc(args: seq[string], server: C2Server) {.async.} =
  echo @(server.cli.handlingClient)

let cmd*: Command = Command(
  execProc: execProc,
  name: "info",
  argsLength: 1,
  usage: @["info"],
  cliMode: @[ClientInteractMode],
  description: "Get more info about a client",
  category: CCClientInteraction
)