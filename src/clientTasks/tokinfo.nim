import std/[net, json, jsonutils]
import ../client/[communication, modules, types]

proc executeTask*(app: App, taskId: int, params: seq[string]) =
  let tokenGroups: seq[tuple[name, sid, domain: string]] = getintegritygroups()
  let tokenIntegrity: string = getintegrity() 
  let taskOutput = TaskOutput(
    task: "output",
    taskId: taskId,
    error: "",
    data: %*{}
  )
  taskOutput.addData(Object, "response", 
    $(%*{
      "tokenGroups": toJson tokenGroups,
      "tokenIntegrity": tokenIntegrity
    })
  )
  app.sendOutput(taskOutput)