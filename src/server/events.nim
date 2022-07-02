import types, teamserverApi

proc onClientConnected*(client: C2Client) =
  sendClients(client.server)
  # echo "new client connected"

proc onClientDisconnected*(client: C2Client) =
  sendClients(client.server)

proc onClientCheckin*(client: C2Client) =
  sendClients(client.server)

proc onClientTasked*(client: C2Client, task: Task) =
  echo "sent task broo"
  sendTaskCreate(client.server, task)
  sendTasks(client.server)

proc onClientTaskCompleted*(client: C2Client, task: Task) =
  sendTaskUpdate(client.server, task)
  sendTasks(client.server)