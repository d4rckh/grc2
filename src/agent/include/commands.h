void executeCmd(int taskActionId, int taskId, int argc, struct TLVBuild * tlv);
void shellCmd(int taskId, int argc, struct TLVBuild * tlv);
void identifyCmd(int taskId, int argc, struct TLVBuild * tlv);
void fsDirCmd(int taskId, int argc, struct TLVBuild * tlv);
void fsOpenFileCmd(int taskId, int argc, struct TLVBuild * tlv);
void fsWriteFileCmd(int taskId, int argc, struct TLVBuild * tlv);
void fsCloseFileCmd(int taskId, int argc, struct TLVBuild * tlv);
void fsReadFileCmd(int taskId, int argc, struct TLVBuild * tlv);