#include <tchar.h>
#include <wchar.h>

#include <Windows.h>
#include <WinInet.h>
#include <stdio.h>

int http_getrequest(
  char * host, 
  int port, 
  char * path, 
  DWORD dwFileSize, 
  DWORD * dwBytesRead, 
  char * buffer
);
int http_postrequest(
  char * host, 
  int port, 
  char * path, 
  unsigned char * buffer, 
  int buffer_length
);