import types, teamserverApi

proc onClientConnected*(client: C2Client) =
  sendClients(client.server)
  sendLoot(client.server)

proc onClientDisconnected*(client: C2Client) =
  sendClients(client.server)

proc onClientCheckin*(client: C2Client) =
  sendClients(client.server)

proc onClientTasked*(client: C2Client, task: Task) =
  sendTasks(client.server)
  sendTaskCreate(client.server, task)

proc onNewLoot*(client: C2Client) =
  sendLoot(client.server)

proc onClientTaskCompleted*(task: Task) =
  sendTaskUpdate(task.client.server, task)
  sendTasks(task.client.server)