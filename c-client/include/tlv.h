struct TLVBuild {
  unsigned char* buf;
  int allocsize;
  int bufsize;
  int read_cursor;
};

void addByte(struct TLVBuild * tlv, char byt);
void addInt32(struct TLVBuild * tlv, int value);
void addString(struct TLVBuild * tlv, char* string);
int extractInt32(struct TLVBuild * tlv);
void extractBytes(struct TLVBuild * tlv, int bytes, char* buffer);
void addBytes(struct TLVBuild * tlv, int size, char* buff);