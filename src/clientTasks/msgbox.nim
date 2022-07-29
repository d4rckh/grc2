import ../client/[communication, types]

from std/json import `%*`
import winim/lean

proc executeTask*(app: App, taskId: int, params: seq[string]) =
  let taskOutput = newTaskOutput taskId

  MessageBox(0, params[0], params[1], 0)
  app.sendOutput(taskOutput)