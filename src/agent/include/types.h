#include <Windows.h>
#include <stdbool.h>

#include <tlv.h>

struct Agent {
  char * report_uri;
  char * token;
  bool connected; 
  
  HANDLE fileHandles[100];

  struct {
    VOID (WINAPI * RtlGetVersion)(POSVERSIONINFOEXW);
  } functions;
};

typedef struct {
  int id;
  void (*function) (int taskId, int argc, struct TLVBuild * tlv);
} Command;

extern struct Agent agent;