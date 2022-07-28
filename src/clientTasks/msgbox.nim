import ../client/[communication, types]

from std/json import `%*`
import winim/lean

proc executeTask*(app: App, taskId: int, params: seq[string]) =
  let taskOutput = TaskOutput(
    task: "output",
    taskId: taskId,
    error: "",
    data: %*{}
  )

  MessageBox(0, params[0], params[1], 0)
  app.sendOutput(taskOutput)