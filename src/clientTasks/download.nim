import std/[net, base64, json, os]
import ../client/communication

proc executeTask*(socket: Socket, taskId: int, params: seq[string]) =
  let taskOutput = TaskOutput(
    task: "output",
    taskId: taskId,
    error: "",
    data: %*{}
  )

  try:
    let contents: string = readFile(params[0])
    taskOutput.addData(DataType.File, splitPath(params[0]).tail, contents)
  except IOError:
    taskOutput.error = getCurrentExceptionMsg()
  socket.sendOutput(taskOutput)