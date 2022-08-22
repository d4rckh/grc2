import winlean

when defined(tcp):
  import std/net
elif defined(http):
  import std/httpclient

type 
  App* = ref object
    ip*: string
    port*: int
    autoConnectTime*: int
    when defined(tcp):
      socket*: Socket
    elif defined(http):
      httpRoot*: string
      token*: string
      httpClient*: HttpClient

type
  USHORT* = uint16
  WCHAR* = distinct int16
  UCHAR* = uint8
#   NTSTATUS* = int32

type OSVersionInfoExW* {.importc: "OSVERSIONINFOEXW", header: "<windows.h>".} = object
  dwOSVersionInfoSize*: ULONG
  dwMajorVersion*: ULONG
  dwMinorVersion*: ULONG
  dwBuildNumber*: ULONG
  dwPlatformId*: ULONG
  szCSDVersion*: array[128, WCHAR]
  wServicePackMajor*: USHORT
  wServicePackMinor*: USHORT
  wSuiteMask*: USHORT
  wProductType*: UCHAR
  wReserved*: UCHAR
