import asyncdispatch, strutils, tables

import ../../types, ../../logging

import ../../../clientTasks/msgbox

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  if len(args) < 2:
    errorLog "you must specify a title and caption for the message box, see 'help msgbox'"
    return
  
  for client in server.cli.handlingClient:
    discard await msgbox.sendTask(client, args[1], args[0])

let cmd*: Command = Command(
  execProc: execProc,
  name: "msgbox",
  argsLength: 2,
  usage: @["msgbox \"[title]\" \"[caption]\""],
  cliMode: @[ClientInteractMode],
  description: "Send a message box (Windows only)",
  category: CCClientInteraction,
  requiresConnectedClient: true
)