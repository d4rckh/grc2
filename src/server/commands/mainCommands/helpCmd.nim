import asyncdispatch, strutils

import ../../types

proc execProc*(args: seq[string], server: C2Server) {.async.} =
  if len(args) > 1:
    for command in server.cli.commands:
      if command.name == args[1]:
        echo "-- " & command.name & " --"
        echo "Category: " & $command.category
        echo "Description: " & command.description
        echo "Usage:\n\t" & command.usage.join("\n\t")
  else:
    for i in CommandCategory:
      echo "-- " & $i
      for command in server.cli.commands:
        if command.category == i:
          echo "\t" & command.name & ": " & command.description

let cmd*: Command = Command(
  execProc: execProc,
  name: "help",
  argsLength: 1,
  usage: @[
    "help",
    "help [command]"
  ],
  description: "Print info about commands available or a specific command",
  category: CCNavigation
)