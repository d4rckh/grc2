import std/[tables, nativesockets, asyncdispatch]
import types, listeners/[tcpListener, httpListener]

let listeners* = @[
  tcpListener.listener,
  httpListener.listener
]

proc startListener*(server: C2Server, title: string, listener: Listener, ipAddress: string, port: Port, config: Table[string, string]): ListenerInstance = 
  result = ListenerInstance(
    port: port,
    config: config,
    ipAddress: ipAddress,
    id: len server.listeners,
    title: title,
    listenerType: listener.name,
    running: false
  )
  asyncCheck listener.startProc(server, result)
  server.listeners.add result

proc stopListener*(server: C2Server, instance: ListenerInstance) = 
  if not instance.stopProc.isNil:
    instance.stopProc()
  server.listeners.delete(
    server.listeners.find instance
  )

export tcpListener
export httpListener