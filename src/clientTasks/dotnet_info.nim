from std/strutils import join

from winim/clr import clrVersions

import ../client/[communication, types]

proc executeTask*(app: App, taskId: int, params: seq[string]) =
  let taskOutput = newTaskOutput taskId

  var dotnetV: seq[string] = @[]
  for version in clrVersions(): dotnetV.add version

  taskOutput.addData(Text, "response", "installed dotnet versions: " & dotnetV.join(", "))
  app.sendOutput(taskOutput)