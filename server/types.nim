import asyncnet

type
  Client* = ref object
    socket*: AsyncSocket
    netAddr*: string
    id*: int
    connected*: bool
    # shit
    loaded*: bool
    hostname*: string

  C2Server* = ref object
    socket*: AsyncSocket
    clients*: seq[Client]

proc `$`*(client: Client): string =
  if not client.loaded:
    $client.id & "(" & client.netAddr & ")"
  else:
    $client.id & "(" & client.netAddr & "):\n\tHostname: " & client.hostname
    