import std/os
import ../client/[communication, types]

proc executeTask*(app: App, taskId: int, params: seq[string]) =
  let taskOutput = newTaskOutput taskId

  try:
    let contents = readFile(params[0])
    taskOutput.addData(DataType.File, splitPath(params[0]).tail, contents)
  except IOError:
    taskOutput.error = getCurrentExceptionMsg()
  
  app.sendOutput(taskOutput)