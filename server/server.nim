import asyncdispatch, asyncnet, threadpool

import strutils

type
  Client = ref object
    socket: AsyncSocket
    netAddr: string
    id: int
    connected: bool

  Server = ref object
    socket: AsyncSocket
    clients: seq[Client]

proc newServer(): Server =
  Server(socket: newAsyncSocket(), clients: @[])

proc `$`(client: Client): string =
  $client.id & "(" & client.netAddr & ")"

proc processMessages(server: Server, client: Client) {.async.} =
  while true:
    let line = await client.socket.recvLine()

    if line.len == 0:
      echo "[-]" ,client, " disconnected!"
      client.connected = false
      client.socket.close()
      return

    # echo(client, " sent: ", line)

    if line == "connect":
      await client.socket.send("hi\r\n")

    for c in server.clients:
      if c.id != client.id and c.connected:
        await c.socket.send(line & "\c\l")

proc loop(server: Server, port = 12345) {.async.} =
  server.socket.bindAddr(port.Port)
  server.socket.listen()
  echo("Listening on localhost:", port)
  
  while true:
    let (netAddr, clientSocket) = await server.socket.acceptAddr()
    echo("[+] new connection from ", netAddr)

    let client = Client(
      socket: clientSocket,
      netAddr: netAddr,
      id: server.clients.len,
      connected: true
    )
    server.clients.add(client)
    asyncCheck processMessages(server, client)

proc prompt(handlingClient: int, server: Server): string = 
  var p: string = ""
  if handlingClient > -1:
    p &= intToStr(handlingClient) & " "
  p &= "> "
  p

proc procStdin(server: Server) {.async.} =
  var handlingClient: int = -1

  stdout.write prompt(handlingClient, server)
  var messageFlowVar = spawn stdin.readLine()
  while true:
    if messageFlowVar.isReady():
      
      let cmd = ^messageFlowVar

      if cmd == "clients":
        for client in server.clients:
          echo client
      if cmd.startsWith("switch"):
        handlingClient = parseInt(cmd.split(" ")[1])
      if cmd == "back":
        handlingClient = -1

      stdout.write prompt(handlingClient, server)
      messageFlowVar = spawn stdin.readLine()
      
    asyncdispatch.poll()

when isMainModule:
  var server = newServer()
  echo("[!] server initialized")
  
  asyncCheck loop(server)
  asyncCheck procStdin(server)