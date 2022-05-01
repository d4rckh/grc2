import strutils, asyncdispatch

import ../../types
import ../../logging

proc execProc*(args: seq[string], server: C2Server) {.async.} =
  let c2cli = server.cli
  for client in server.clients:
    if client.id == parseInt(args[1]):
      c2cli.handlingClient = client
      c2cli.mode = ClientInteractMode
  if c2cli.handlingClient.isNil() or c2cli.handlingClient.id != parseInt(args[1]):
    infoLog "client not found"

let cmd*: Command = Command(
  execProc: execProc,
  name: "interact",
  argsLength: 2,
  usage: @[
    "interact [clientID]",
  ],
  description: "Interact with a client",
  category: CCClientInteraction
)