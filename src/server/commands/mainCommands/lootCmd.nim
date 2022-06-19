import asyncdispatch, tables, os, terminal

import ../../types, ../../loot

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  for client in server.clients:
    stdout.styledWriteLine fgGreen, "-- " & $client
    let daLoot = getLoot(client)
    stdout.styledWriteLine fgYellow, "  Images: "
    for loot in daLoot:
      if loot.t == LootImage:
        let (_, name, ext) = splitFile(loot.file)
        echo "  | " & name & ext
    stdout.styledWriteLine fgYellow, "  Files: "
    for loot in daLoot:
      if loot.t == LootFile:
        let (_, name, ext) = splitFile(loot.file)
        echo "  | " & name & ext
    
let cmd*: Command = Command(
  execProc: execProc,
  name: "loot",
  argsLength: 0,
  usage: @[
    "loot",
  ],
  description: "Manage loot pog",
  category: CCTasks
)