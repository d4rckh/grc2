#include <types.h>

int isHandleValid(int index)
{
  if (index < 1000 && 0 <= index &&
      agent.fileHandles[index] != 0 && 
      agent.fileHandles[index] != INVALID_HANDLE_VALUE) 
  return 1;
  else return 0;
}