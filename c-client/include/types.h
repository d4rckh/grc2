#include <Windows.h>

struct Agent {
  char * report_uri;
  char * token;    
  
  struct {
    VOID (WINAPI * RtlGetVersion)(POSVERSIONINFOEXW);
  } functions;
};



extern struct Agent agent;