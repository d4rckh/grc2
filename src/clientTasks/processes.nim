import std/net
import ../client/[communication, modules, types]

import tlv

proc executeTask*(app: App, taskId: int, params: seq[string]) =
  let taskOutput = newTaskOutput taskId

  let processes: seq[tuple[name: string, id: int]] = getprocesses()

  let b = initBuilder()
  b.addInt32(cast[int32](len processes))

  for process in processes:
    b.addInt32(cast[int32](process.id))
    b.addString(process.name)

  taskOutput.data = b.encodeString()

  app.sendOutput(taskOutput)
