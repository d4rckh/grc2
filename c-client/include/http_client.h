#include <tchar.h>
#include <wchar.h>

#include <Windows.h>
#include <WinInet.h>
#include <stdio.h>

int httpGet(
  char * host, 
  int port, 
  char * path, 
  DWORD dwFileSize, 
  DWORD * dwBytesRead, 
  char * buffer
);

int httpPost(
  char * host, 
  int port, 
  char * path, 
  unsigned char * buffer, 
  int buffer_length
);