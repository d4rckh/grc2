import ../client/[communication, types]

import tlv

proc executeTask*(app: App, taskId: int, params: seq[string]) =
  let taskOutput = newTaskOutput taskId

  try:
    let b = initBuilder()
    b.addString(readFile(params[0]))
    taskOutput.data = b.encodeString()
  except:
    taskOutput.error = getCurrentExceptionMsg()
  
  app.sendOutput(taskOutput)