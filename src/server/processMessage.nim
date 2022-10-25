import std/[
  asyncdispatch, 
  asyncfutures, 
  strutils, 
  strformat, 
  md5
]

import tlv

import types, logging, communication, events, tasks

proc generateClientHash(c: C2Client) =
  c.hash = getMD5(
    fmt"{c.ipAddress}{c.hostname}{c.username}{c.osType}{$c.windowsVersionInfo}"
  )

proc processMessage*(client: ref C2Client, listenerInstance: ListenerInstance, response: string) {.async.} = 
  let server = client.server

  if not (client[] in server.clients):
    server.clients.add client[]

  client.lastHandledBy = listenerInstance

  let p = initParser()
  p.setBuffer(cast[seq[byte]](response))

  let taskId = p.extractInt32() 
  let taskName = p.extractString()
  let error = p.extractString()
  let data = p.extractString()
  
  if taskId < 0:
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
      let p = initParser()
      p.setBuffer(cast[seq[byte]](data))
      
      client.username = p.extractString()
      client.hostname = p.extractString()
      client.isAdmin = p.extractBool()
      client.osType = parseEnum[OSType](p.extractString())
      client.pid = p.extractInt32()
      client.pname = p.extractString()
      client.windowsVersionInfo = WindowsVersionInfo(
        majorVersion: p.extractInt32(),
        minorVersion: p.extractInt32(),
        buildNumber: p.extractInt32()
      )

      client[].generateClientHash()

      if not client.loaded:
        client.loaded = true
        onClientConnected(client[])
        cConnected client[]
    of "output":
      infoLog $client[] & " completed task " & task.actionName

    task.output = TaskOutput(
      error: error,
      data: data
    )

    task.markAsCompleted()
