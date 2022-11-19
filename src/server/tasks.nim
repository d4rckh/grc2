import std/asyncfutures, tlv

import types

proc isError*(task: Task): bool = 
  task.output.error != ""

proc markAsCompleted*(task: Task) = 
  if task.isError(): task.status = TaskCompletedWithError
  else: task.status = TaskCompleted

  if not task.future[].isNil():
    task.future[].complete()
    task.future[] = nil

proc toTLV*(task: Task): string =
  let b = initBuilder()
  
  b.addInt32(cast[int32](task.id))
  b.addInt32(cast[int32](task.action))

  # let bArgs = initBuilder()  
  # bArgs.addInt32(cast[int32](len task.arguments))
  # for argument in task.arguments: bArgs.addString(argument)
  
  b.addString(cast[string](task.dataBuf))
    
  return b.encodeString()