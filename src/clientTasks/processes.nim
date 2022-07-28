import std/[os, net, json, jsonutils]
import ../client/[communication, modules, types]

proc executeTask*(app: App, taskId: int, params: seq[string]) =
  let processes: seq[tuple[name: string, id: int]] = getprocesses()
  let taskOutput = TaskOutput(
    task: "output",
    taskId: taskId,
    error: "",
    data: %*{}
  )

  taskOutput.addData(Object, "processes", $(toJson processes))
  app.sendOutput(taskOutput)
