when defined(windows):
  import winim, bitops, strutils
  import types
  import windowsUtils

  proc rtlGetVersion(lpVersionInformation: var types.OSVersionInfoExW): NTSTATUS
    {.cdecl, importc: "RtlGetVersion", dynlib: "ntdll.dll".}
    
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

proc getprocesses*(): seq[tuple[name: string, id: int]] =
  var psList: seq[tuple[name: string, id: int]] = @[]
  when defined(windows):
    var aProcesses: array[512, DWORD]
    var cbNeeded: DWORD 
    var cProcesses: DWORD

    if EnumProcesses(cast[ptr DWORD](addr aProcesses), DWORD(sizeof(aProcesses)), addr cbNeeded) == FALSE:
      return psList

    cProcesses = DWORD((cbNeeded / sizeof(DWORD)))

    for i in 0..(cProcesses - 1):
      if aProcesses[i] != 0:
        
        var szProcessName = newString(MAX_PATH)
        
        var hProcess: HANDLE = OpenProcess( bitor(PROCESS_QUERY_INFORMATION, PROCESS_VM_READ),
          FALSE, aProcesses[i] );

        var hMod: HMODULE
        var cbNeeded: DWORD
        
        if EnumProcessModules( hProcess, addr hMod, DWORD(sizeof(hMod)), addr cbNeeded ):
          let sz = GetModuleBaseNameA(hProcess, hMod, szProcessName.cstring, DWORD szProcessName.len);
          szProcessName.setLen(sz)
          if len(szProcessName) != 0:
            psList.add((name: szProcessName, id: int aProcesses[i]))
  
  return psList

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
          return sidToString(tokIntegrity.Label.Sid)
        LocalFree(allocated)
  else:
    return ""

proc getintegritygroups*(): seq[tuple[name, sid, domain: string]] =
  var groups: seq[tuple[name, sid, domain: string]] = @[]

  when defined(windows):
    var hToken: HANDLE
    
    if OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, addr hToken) == FALSE:
      return groups
    

    var cbSize: DWORD = 0
    if GetTokenInformation(hToken, tokenGroups, NULL, 0, addr cbSize) == FALSE:
      if GetLastError() == ERROR_INSUFFICIENT_BUFFER:
        var allocated = LocalAlloc(LPTR, cbSize)
        var tokGroups: PTOKEN_GROUPS = cast[PTOKEN_GROUPS](allocated)
        if GetTokenInformation(hToken, tokenGroups, tokGroups, cbSize, addr cbSize):
          let groupArray: ptr UncheckedArray[SID_AND_ATTRIBUTES] = cast[ptr UncheckedArray[SID_AND_ATTRIBUTES]](addr tokGroups.Groups)
          for i in 0..(tokGroups.GroupCount - 1):
            
            let sid = groupArray[i].Sid

            var nameSize: DWORD = 0
            var domainNameSize: DWORD = 0

            var groupName: LPWSTR
            var domainName: LPWSTR
            var peUse: SID_NAME_USE

            var gnString = ""
            var dnString = ""

            if LookupAccountSidW(nil, sid, groupName, addr nameSize, domainName, addr domainNameSize, addr peUse) == FALSE:
              if GetLastError() == ERROR_INSUFFICIENT_BUFFER:
                var gnAlloc = LocalAlloc(LPTR, nameSize * 2)
                groupName = cast[LPWSTR](gnAlloc)
                var dnAlloc = LocalAlloc(LPTR, domainNameSize * 2)
                domainName = cast[LPWSTR](dnAlloc)
                if LookupAccountSidW(nil, sid, groupName, addr nameSize, domainName, addr domainNameSize, addr peUse):
                  gnString = $cast[WideCStringObj](groupName)
                  dnString = $cast[WideCStringObj](domainName)

                LocalFree(gnAlloc)
                LocalFree(dnAlloc)

            groups.add((
              name: gnString, sid: sidToString(sid),
              domain: dnString
            ))
        LocalFree(allocated)
      else:
        echo GetLastError()
    
    return groups
  else:
    return groups

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
