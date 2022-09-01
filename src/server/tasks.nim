import std/asyncfutures, tlv

import types, events

proc isError*(task: Task): bool = 
  task.output.error != ""

proc markAsCompleted*(task: Task) = 
  if task.isError(): task.status = TaskCompletedWithError
  else: task.status = TaskCompleted

  if not task.future[].isNil():
    task.future[].complete()
    task.future[] = nil

  onClientTaskCompleted(task)

proc toTLV*(task: Task): string =
  let b = initBuilder()
  
  b.addInt32(cast[int32](task.id))
  b.addString(task.action)

  b.addInt32(cast[int32](len task.arguments))
  for argument in task.arguments: b.addString(argument)

  return b.encodeString()