import ../prelude

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  if server.clients.len == 0:
    infolog "no clients connected"
    return

  var table: JsonNode = %*[]
  for client in server.clients:
    table.add %*{
      "client": $client,
      "last check in": client.get_last_checkin(),
      "process": $client.pid,
    }
  
  printTable(table)
  infoLog $server.clients.len & " clients"

let cmd*: Command = Command(
  execProc: execProc,
  name: "clients",
  aliases: @["c"],
  argsLength: 0,
  usage: @["clients"],
  description: "View clients that were connected and are currently connected",
  category: CCClientInteraction
)