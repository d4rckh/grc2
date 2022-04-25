import winim/[inc/lm, lean]
import nativesockets

when defined(windows):
    proc hostname*(): string =
        getHostname()
    proc username*(): string =
        var
            buffer = newString(UNLEN + 1)
            cb = DWORD buffer.len
        GetUserNameA(&buffer, &cb)
        buffer.setLen(cb - 1)
        buffer
