import winlean

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
