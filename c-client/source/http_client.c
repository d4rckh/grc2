#define _UNICODE

#include <tchar.h>
#include <wchar.h>

#include <Windows.h>
#include <WinInet.h>
#include <stdio.h>

int httpGet(char * host, int port, char * path, DWORD dwFileSize, DWORD * dwBytesRead, char * buffer) {
  HINTERNET hSession = InternetOpen(
    "Mozilla/5.0",
    INTERNET_OPEN_TYPE_PRECONFIG,
    NULL, NULL, 0
  );

  HINTERNET hConnect = InternetConnect(hSession, host, port, "", "", INTERNET_SERVICE_HTTP, 0, 0);
  HINTERNET hHttpFile = HttpOpenRequest(hConnect, "GET", path, NULL, NULL, NULL, 0, 0);

  if (!HttpSendRequest(hHttpFile, NULL, 0, 0, 0)) {
    printf("HttpSendRequest Error: (%lu)\n", GetLastError());
    return 0;
  }

  if (!InternetReadFile(hHttpFile, buffer, dwFileSize + 1, dwBytesRead)) {
    printf("InternetReadFile Error: (%lu)", GetLastError());
  }

  return 1;
}

int httpPost(char * host, int port, char * path, unsigned char * buffer, int buffer_length) {
  HINTERNET hSession = InternetOpen(
    "Mozilla/5.0",
    INTERNET_OPEN_TYPE_PRECONFIG,
    NULL, NULL, 0
  );

  HINTERNET hConnect = InternetConnect(hSession, host, port, "", "", INTERNET_SERVICE_HTTP, 0, 0);
  HINTERNET hHttpFile = HttpOpenRequest(hConnect, "POST", path, NULL, NULL, NULL, 0, 0);

  if (!HttpSendRequest(hHttpFile, NULL, 0, buffer, buffer_length)) {
    printf("HttpSendRequest Error: (%lu)\n", GetLastError());
    return 0;
  }

  return 1;
}