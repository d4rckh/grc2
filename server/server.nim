import asyncdispatch, asyncfutures
import types, logging, cli
import listeners/tcp

infoLog "initializing c2 server"

let server = C2Server(
  tcpListeners: @[], 
  clients: @[],
  clRespFuture: new (ref Future[void]),
  svStartFuture: new (ref Future[void])
)

asyncCheck server.createNewTcpListener(1234, "127.0.0.1")
asyncCheck procStdin(server)

try:
  runForever()
except OSError: discard