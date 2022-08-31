import std/[json, jsonutils, times]

import ../types, ../loot

proc clientToJson*(client: C2Client): JsonNode =
  %*{
    "id": client.id,
    "hash": client.hash,
    "ipAddress": client.ipAddress,
    "hostname": client.hostname,
    "username": client.username,
    "osType": client.osType,
    "lastCheckin": client.lastCheckin.toTime.toUnix,
    "windowsVersionInfo": client.windowsVersionInfo,
    "initialized": client.loaded
  }

proc lootToJson*(loot: Loot): JsonNode =
  %*{
    "client": loot.client.id,
    "t": $loot.t,
    "file": loot.file,
    "data": loot.data
  }

proc taskToJson*(task: Task): JsonNode =
  %*{
    "client": task.client.id,
    "id": task.id,
    "action": task.action,
    "status": $task.status,
    "arguments": toJson task.arguments,
    "output": task.output
  }