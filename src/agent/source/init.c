#include <Windows.h>
#include <types.h>

void init() {
  agent.connected = false;
  
  agent.functions.RtlGetVersion = (void (*)(POSVERSIONINFOEXW))GetProcAddress(
    GetModuleHandle("ntdll.dll"), "RtlGetVersion"
  );

  for (int i = 0; i < 100; i++) 
    agent.fileHandles[i] = 0; 
}