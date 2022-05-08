when defined(windows):
  import winim

  proc convertSidToStringSidA(Sid: PSID, StringSir: ptr LPSTR): NTSTATUS
    {.cdecl, importc: "ConvertSidToStringSidA", dynlib: "Advapi32.dll".}



when defined(windows):
  proc sidToString*(sid: PSID): string =
    var lpSid: LPSTR

    discard convertSidToStringSidA(
      sid,
      addr lpSid
    )
    
    return $cstring(lpSid)
