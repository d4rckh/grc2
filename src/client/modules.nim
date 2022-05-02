when defined(windows):
  import winim/[inc/lm, lean]
  import types

  proc rtlGetVersion(lpVersionInformation: var types.OSVersionInfoExW): NTSTATUS
    {.cdecl, importc: "RtlGetVersion", dynlib: "ntdll.dll".}


import os
import nativesockets

proc hostname*(): string =
  getHostname()

proc areWeAdmin*(): bool =
  isAdmin()

when defined(windows):
  proc username*(): string =
    var
      buffer = newString(UNLEN + 1)
      cb = DWORD buffer.len
    GetUserNameA(&buffer, &cb)
    buffer.setLen(cb - 1)
    buffer
  proc msgbox*(title: string, caption: string): bool =
    MessageBox(0, title, caption, 0)
    return true

proc getwindowosinfo*(): tuple[majorVersion: int, minorVersion: int, buildNumber: int] =
  when defined(windows):
    var osInfo: types.OSVersionInfoExW
    discard rtlGetVersion(osInfo)
    return (majorVersion: int(osInfo.dwMajorVersion), minorVersion: int(osInfo.dwMinorVersion), buildNumber: int(osInfo.dwBuildNumber))
  else:
    return (
      majorVersion: 0,
      minorVersion: 0,
      buildNumber: 0
    )

proc getlinuxosinfo*(): tuple[kernelVersion: string] =
  return (kernelVersion: "placeholder")

when defined(linux):
  proc msgbox*(title: string, caption: string): bool =
    return false
  proc username*(): string =
    getEnv("USERNAME", getEnv("USER", "[no username envvar found]"))
