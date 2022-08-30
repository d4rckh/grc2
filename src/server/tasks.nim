import std/[json, strutils, base64, times, asyncfutures], pixie

import types, logging, loot, events

proc isError*(task: Task): bool = 
  task.output.error != ""

proc parseTaskOutput*(response: JsonNode = %*{}): seq[TaskData] =
  result = @[]
  for key, value in pairs(response):
    if not key.contains("::"):
      if [JObject, JArray].contains(response.kind):     
        result.add TaskData(
          name: "data",
          dataType: DataObject,
          content: $response
        )
      break

    let dataName = key.split("::")[0]
    let dataType = key.split("::")[1]

    let dataContent = decode(value.getStr())
    
    result.add TaskData(
      name: dataName,
      dataType: parseEnum[TaskDataType](dataType),
      content: dataContent
    )

proc markAsCompleted*(task: Task) = 
  if task.isError(): task.status = TaskCompletedWithError
  else: task.status = TaskCompleted

  if not task.future[].isNil():
    task.future[].complete()
    task.future[] = nil

  onClientTaskCompleted(task)

proc logTaskOutput*(task: Task, save: bool = false) = 
  for taskData in task.output.data:
    case taskData.dataType:
    of DataText:
      infoLog taskData.content, colorText=false
    of DataFile:
      if save:
        let filePath = task.client.getLootDirectory() & "/files/" & taskData.name
        writeFile filePath, taskData.content
        successLog "you got new loot!"
        onNewLoot(task.client)
    of DataObject:
      let dataObject = parseJson(taskData.content)
      if dataObject.kind == JObject: printObject(dataObject)
      elif dataObject.kind == JArray: printTable(dataObject)
    of DataImage:
      if save:
        let image = decodeImage(taskData.content)
        let filePath = task.client.getLootDirectory() & 
        "/images/" & taskData.name & "_" & now().format("yyyy-MM-dd-HH-mm-ss") & ".png"
        image.writeFile(filePath)
        successLog "you got new loot!"
        onNewLoot(task.client)
