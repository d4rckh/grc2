import std/[json, strutils, base64, times, asyncfutures], pixie

import types, logging, loot, events

proc isError*(task: Task): bool = 
  task.output.error != ""

proc markAsCompleted*(task: Task) = 
  if task.isError(): task.status = TaskCompletedWithError
  else: task.status = TaskCompleted

  if not task.future[].isNil():
    task.future[].complete()
    task.future[] = nil

  onClientTaskCompleted(task)

