import asyncdispatch, asyncfutures
import types, logging, cli

infoLog "initializing c2 server"

var server = C2Server(
  tcpListeners: @[], 
  clients: @[],
  clRespFuture: new (ref Future[void]),
  svStartFuture: new (ref Future[void])
)

asyncCheck procStdin(server)

runForever()