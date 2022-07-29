import std/[net, json, jsonutils]
import ../client/[communication, modules, types]

proc executeTask*(app: App, taskId: int, params: seq[string]) =
  let taskOutput = newTaskOutput taskId

  let processes: seq[tuple[name: string, id: int]] = getprocesses()
  taskOutput.addData(Object, "processes", $(toJson processes))
  app.sendOutput(taskOutput)
