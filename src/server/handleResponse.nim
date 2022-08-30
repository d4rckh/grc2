import std/json

import types, tasks

proc handleResponse*(task: Task, response: JsonNode = %*[]) = 
  task.output.data = parseTaskOutput(response["data"])
  task.output.error = response["error"].getStr("")