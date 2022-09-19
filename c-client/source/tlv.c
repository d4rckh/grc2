#include <stdlib.h>
#include <string.h>

struct TLVBuild {
  unsigned char* buf;
  int allocsize;
  int bufsize;
  int read_cursor;
};

void addByte(struct TLVBuild * tlv, char byt) {
  if (tlv->bufsize >= tlv->allocsize) {
    tlv->buf = realloc(tlv->buf, tlv->bufsize+512);
  }
  tlv->buf[tlv->bufsize] = byt;
  tlv->bufsize++;
}

void addInt32(struct TLVBuild * tlv, int value) {
  // little endian
  addByte(tlv, (value >> 0) & 0XFF);
  addByte(tlv, (value >> 8) & 0XFF);
  addByte(tlv, (value >> 16) & 0XFF);
  addByte(tlv, (value >> 24) & 0xFF);
}

void addString(struct TLVBuild * tlv, char* string) {
  addInt32(tlv, strlen(string));
  for (int i = 0; i < strlen(string); i ++) {
    addByte(tlv, string[i]);
  }
}

int extractInt32(struct TLVBuild * tlv) {
  tlv->read_cursor += 4;
  return tlv->buf[tlv->read_cursor - 4] | 
        (tlv->buf[tlv->read_cursor - 3] << 8) | 
        (tlv->buf[tlv->read_cursor - 2] << 16) | 
        (tlv->buf[tlv->read_cursor - 1] << 24);
}

void extractBytes(struct TLVBuild * tlv, int bytes, char* buffer) {
  for (int i = 0; i < bytes; i++) {
    buffer[i] = tlv->buf[tlv->read_cursor + i];
  }
  tlv->read_cursor += bytes;
}

void addBytes(struct TLVBuild * tlv, int size, char* buff) {
  addInt32(tlv, size);
  for (int i = 0; i < size; i ++) {
    addByte(tlv, buff[i]);
  }
}