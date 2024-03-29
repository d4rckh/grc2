import ../prelude

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  if len(args) >= 1:
    for command in server.cli.commands:
      if command.name == args[0] or args[0] in command.aliases:
        echo "-- " & command.name & " --"
        echo "Aliases: " & command.aliases.join(", ")
        echo "Category: " & $command.category
        echo "Description: " & command.description
        echo "Usage:\n\t" & command.usage.join("\n\t")
  else:
    for i in CommandCategory:
      stdout.styledWriteLine fgGreen, "-- ", $i
      for command in server.cli.commands:
        if command.category == i:
          stdout.styledWriteLine "\t", fgYellow, command.name, fgWhite, ": ", command.description

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