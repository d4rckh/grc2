when defined(windows):
    import winim/[inc/lm, lean]

import os
import nativesockets

proc hostname*(): string =
    getHostname()

proc areWeAdmin*(): bool =
    isAdmin()

when defined(windows):
    proc username*(): string =
        var
            buffer = newString(UNLEN + 1)
            cb = DWORD buffer.len
        GetUserNameA(&buffer, &cb)
        buffer.setLen(cb - 1)
        buffer
    proc msgbox*(title: string, caption: string): bool =
        MessageBox(0, title, caption, 0)
        return true

when defined(linux):
    proc msgbox*(title: string, caption: string): bool =
        return false
    proc username*(): string =
        getEnv("USERNAME", getEnv("USER", "[no username envvar found]"))