import std/[
  asyncdispatch, 
  asyncnet,
  asyncfutures, 
  strutils, 
  json
]

import teamserverApi

import types, logging, communication

proc processMessages(server: C2Server, tcpSocket: AsyncSocket) {.async.} =

  while true:
    let line = await tcpSocket.recvLine(maxLength=1000000)

    if line.len == 0:
      tcpSocket.close()
      break
 
    echo line
    if line == "connected": 
      server.sendClients()
      server.sendTasks()
    else:
      let j = parseJson(line)
      let event = j["event"].getStr()
      case event:
      of "sendtask":
        discard await sendClientTask(
          server.getClientById(j["clientId"].getInt()),
          j["taskName"].getStr(),
          j["taskParams"]  
        )
    

proc startTcpApi*(server: C2Server, port = 5051, ip = "127.0.0.1") {.async.} =
  
  let tcpSocket = newAsyncSocket()
  try:
    tcpSocket.setSockOpt(OptReuseAddr, true)
    tcpSocket.bindAddr(port.Port, ip)
    tcpSocket.listen()
    echo "listening"
  except OSError:
    errorLog getCurrentExceptionMsg()
    return
  
  while true:
    let 
      (netAddr, clientSocket) = await tcpSocket.acceptAddr()
    server.teamserverClients.add clientSocket
    asyncCheck processMessages(server, clientSocket)