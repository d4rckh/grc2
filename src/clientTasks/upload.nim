import net, base64, json
import ../client/communication

proc executeTask*(socket: net.Socket, taskId: int, params: seq[string]) =
  let taskOutput = TaskOutput(
    task: "output",
    taskId: taskId,
    error: "",
    data: %*{}
  )

  let fileContents = decode(params[0])
  writeFile(params[1], fileContents)
  
  taskOutput.addData(Text, "result", "received file " & params[1] & " (length: " & $len(fileContents) & ")")
  socket.sendOutput(taskOutput)