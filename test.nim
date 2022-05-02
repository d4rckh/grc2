

proc rtlGetVersion(lpVersionInformation: var OSVersionInfoExW): NTSTATUS
  {.cdecl, importc: "RtlGetVersion", dynlib: "ntdll.dll".}

var versionInfo: OSVersionInfoExW
echo rtlGetVersion(versionInfo)
echo versionInfo
