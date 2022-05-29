import strutils, asyncdispatch, tables

import ../../types
import ../../logging

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  if len(args) < 1:
    errorLog "you must provide a client id to interact with"
    return

  let c2cli = server.cli

  c2cli.handlingClient = @[]
  
  for arg in args:
    let clientId = parseInt(arg)
    var cFound = false
    for client in server.clients:
      if client.id == clientId:
        c2cli.handlingClient.add client
        c2cli.mode = ClientInteractMode
        cFound = true

    if not cFound:
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