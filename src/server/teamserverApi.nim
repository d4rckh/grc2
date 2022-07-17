import std/[marshal, json, asyncnet]

import types, utils/jsonConverters, loot

proc sendClients*(server: C2Server) =
  for tsClient in server.teamserverClients:
    if not tsClient.isClosed:
      var jsonData: JsonNode = %*[]
      for client in server.clients:
        jsonData.add clientToJson client
      discard tsClient.send($(%*{
        "event": "clients",
        "data": jsonData
      }) & "\r\n")

proc sendTasks*(server: C2Server) =
  for tsClient in server.teamserverClients:
    if not tsClient.isClosed:
      var jsonData: JsonNode = %*[]
      for task in server.tasks:
        jsonData.add taskToJson task
      discard tsClient.send($(%*{
        "event": "tasks",
        "data": jsonData
      }) & "\r\n")

proc sendTaskUpdate*(server: C2Server, task: Task) =
  for tsClient in server.teamserverClients:
    if not tsClient.isClosed:
      
      discard tsClient.send($(%*{
        "event": "taskupdate",
        "data": taskToJson task
      }) & "\r\n")

proc sendLoot*(server: C2Server) =
  for tsClient in server.teamserverClients:
    if not tsClient.isClosed:
      var jsonData: JsonNode = %*[]
      for client in server.clients:
        if client.loaded:
          for loot in client.getLoot():
            jsonData.add lootToJson loot
      discard tsClient.send($(%*{
        "event": "loot",
        "data": jsonData
      }) & "\r\n")

proc sendTaskCreate*(server: C2Server, task: Task) =
  for tsClient in server.teamserverClients:
    if not tsClient.isClosed:
      
      discard tsClient.send($(%*{
        "event": "taskcreate",
        "data": taskToJson task
      }) & "\r\n")