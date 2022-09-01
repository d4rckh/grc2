import winim/com
import ../client/[communication, types]

import tlv

proc executeTask*(app: App, taskId: int, params: seq[string]) =
  let taskOutput = newTaskOutput taskId
  
  var wmi = GetObject "winmgmts:{impersonationLevel=impersonate}!\\\\.\\root\\SecurityCenter2"

  var antiviruses: seq[tuple[name: string]] = @[]
  for av in wmi.execQuery "select * from AntivirusProduct":
    antiviruses.add (name: $av.displayName)
  
  let b = initBuilder()
  b.addInt32(cast[int32](len antiviruses))
  for av in antiviruses: b.addString(av.name)

  taskOutput.data = b.encodeString()
  
  app.sendOutput taskOutput