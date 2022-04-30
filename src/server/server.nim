import asyncdispatch, asyncfutures
import types, logging, cli

infoLog "initializing c2 server"

let server = C2Server()

# when defined(debug):
import listeners/tcp
asyncCheck server.createNewTcpListener(1234, "127.0.0.1")

asyncCheck procStdin(server)

try:
  runForever()
except OSError: discard