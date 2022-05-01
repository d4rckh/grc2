import asyncdispatch, threadpool, asyncfutures
import strutils 

import types, logging

import ../clientTasks/shell
import commands/mainCommands/backCmd
import communication

proc procStdin*(server: C2Server) {.async.} =

  let c2cli = server.cli
  c2cli.initialized = true

  prompt(server)

  var messageFlowVar = spawn stdin.readLine()
  while true:
    if messageFlowVar.isReady():
      
      let input = ^messageFlowVar
      let args = input.split(" ")
      let cmd = args[0]
      
      if c2cli.mode == ShellMode:
        if cmd == "back":
          await backCmd.cmd.execProc(args, server)
        else:
          let task = await shell.sendTask(server.cli.handlingClient, args.join(" "))
          await task.awaitResponse()
      else:
        for command in c2cli.commands:
          if command.name == cmd:
            if command.cliMode == @[ClientInteractMode] and c2cli.mode != ClientInteractMode:
              errorLog "you must interact with a client to use this command (see 'help interact')"
              continue
            if command.argsLength <= len(args):
              await command.execProc(args, server)
            else:
              errorLog "Invalid Usage. Correct usage:\n\t" & command.usage.join("\n\t")

      prompt(server)
      messageFlowVar = spawn stdin.readLine() 
      
    await asyncdispatch.sleepAsync(100)