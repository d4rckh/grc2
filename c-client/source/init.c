#include <Windows.h>
#include <types.h>

void init() {
  agent.functions.RtlGetVersion = (void (*)(POSVERSIONINFOEXW))GetProcAddress(
    GetModuleHandle("ntdll.dll"), "RtlGetVersion"
  );
}