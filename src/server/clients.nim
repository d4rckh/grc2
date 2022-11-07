import tlv, std/[strutils, strformat, md5]
import types, logging

proc generateClientHash(c: C2Client): string =
  return getMD5(
    fmt"{c.ipAddress}{c.hostname}{c.username}{c.osType}{$c.windowsVersionInfo}"
  )

proc identify*(client: C2Client, data: string) =
  let p = initParser()
  p.setBuffer(cast[seq[byte]](data))
  
  client.username = p.extractString()
  client.hostname = p.extractString()
  client.isAdmin = p.extractBool()
  client.osType = parseEnum[OSType](p.extractString())
  client.pid = p.extractInt32()
  client.pname = p.extractString()
  client.windowsVersionInfo = WindowsVersionInfo(
    majorVersion: p.extractInt32(),
    minorVersion: p.extractInt32(),
    buildNumber: p.extractInt32()
  )

  client.hash = generateClientHash client
  
proc getClientByHash*(server: C2Server, hash: string): C2Client =
  for client in server.clients: 
    if client.hash == hash: return client

proc getClientById*(server: C2Server, id: string): C2Client =
  for client in server.clients: 
    if client.id == id: return client
