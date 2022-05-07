when defined(windows):
  import winim/[inc/lm, lean]
  import types

  proc rtlGetVersion(lpVersionInformation: var types.OSVersionInfoExW): NTSTATUS
    {.cdecl, importc: "RtlGetVersion", dynlib: "ntdll.dll".}
  
  proc convertSidToStringSidA(Sid: PSID, StringSir: ptr LPSTR): NTSTATUS
    {.cdecl, importc: "ConvertSidToStringSidA", dynlib: "Advapi32.dll".}
  
  proc betterLocalAlloc*(uFlags: UINT, uBytes: SIZE_T): PVOID 
    {.cdecl, importc: "LocalAlloc", dynlib: "Kernel32.dll".}

  # {.compile: "cppModules.cpp".}
  # proc getIntegritySid(a: ref string): int {.importc.}


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

proc getintegrity*(): string =
  when defined(windows):
    var hToken: HANDLE
    
    if OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, addr hToken) == FALSE:
      return ""
    
    var cbSize: DWORD = 0
    if GetTokenInformation(hToken, tokenIntegrityLevel, NULL, 0, addr cbSize) == FALSE:
      if GetLastError() == ERROR_INSUFFICIENT_BUFFER:
        var allocated = LocalAlloc(LPTR, cbSize)
        var tokIntegrity: PTOKEN_MANDATORY_LABEL = cast[PTOKEN_MANDATORY_LABEL](allocated)
        if GetTokenInformation(hToken, tokenIntegrityLevel, tokIntegrity, cbSize, addr cbSize):
          var lpSid: LPSTR
          discard convertSidToStringSidA(
            tokIntegrity.Label.Sid,
            addr lpSid
          )
          LocalFree(allocated)
          return $cstring(lpSid)
  else:
    return ""

proc getintegritygroups*(): string =
  when defined(windows):
    var hToken: HANDLE
    
    if OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, addr hToken) == FALSE:
      return ""
    
    var cbSize: DWORD = 0
    if GetTokenInformation(hToken, tokenGroups, NULL, 0, addr cbSize) == FALSE:
      if GetLastError() == ERROR_INSUFFICIENT_BUFFER:
        var allocated = LocalAlloc(LPTR, cbSize)
        var tokGroups: PTOKEN_GROUPS = cast[PTOKEN_GROUPS](allocated)
        echo tokGroups.GroupCount
        for group in tokGroups.Groups:
          var lpSid: LPSTR
          discard convertSidToStringSidA(
            group.Sid,
            addr lpSid
          )
          echo $cstring(lpSid)
        return "lets go"
  else:
    return ""

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
