import asyncdispatch, strutils, tables

import ../../types

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  if len(args) >= 1:
    for command in server.cli.commands:
      if command.name == args[0]:
        echo "-- " & command.name & " --"
        echo "Aliases: " & command.aliases.join(", ")
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
  argsLength: 0,
  usage: @[
    "help",
    "help [command]"
  ],
  description: "Print info about commands available or a specific command",
  category: CCNavigation
)