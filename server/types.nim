import asyncnet

type
  Client* = ref object
    socket*: AsyncSocket
    netAddr*: string
    id*: int
    connected*: bool

  Server* = ref object
    socket*: AsyncSocket
    clients*: seq[Client]

proc `$`*(client: Client): string =
  $client.id & "(" & client.netAddr & ")"
