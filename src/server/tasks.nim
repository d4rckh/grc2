import std/asyncfutures, pixie

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

