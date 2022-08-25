import std/[json, strutils, base64, times], pixie

import types, logging, loot, events

proc handleResponse*(client: C2Client, rewind: bool, response: JsonNode) = 
  if response{"data"}.isNil():
    errorLog "task does not have data"
  else:
    for key, value in pairs(response["data"]):
      if not key.contains("::"):
        if response["data"].kind == JObject: printObject(response["data"])
        elif response["data"].kind == JArray: printTable(response["data"])
        break
      let dataName = key.split("::")[0]
      let dataType = key.split("::")[1]
      let dataContent = decode(value.getStr())
      if not rewind: infoLog "received " & dataType & " (" & dataName & ") from " & $client
      case dataType:
      of "text":
        echo "--------------"
        infoLog dataContent, colorText=false
        echo "--------------"
      of "file":
        if not rewind:
          let filePath = client.getLootDirectory() & "/files/" & dataName
          writeFile filePath, dataContent
          successLog "you got new loot!"
          onNewLoot(client)
      of "object":
        let dataObject = parseJson(dataContent)
        if dataObject.kind == JObject: printObject(dataObject)
        elif dataObject.kind == JArray: printTable(dataObject)
      of "image":
        if not rewind:
          let image = decodeImage(dataContent)
          let filePath = client.getLootDirectory() & 
          "/images/" & dataName & "_" & now().format("yyyy-MM-dd-HH-mm-ss") & ".png"
          image.writeFile(filePath)
          successLog "you got new loot!"
          onNewLoot(client)

  if client.server.cli.waitingForOutput:
    client.server.cli.waitingForOutput = false
    prompt(client.server)
