import nativesockets

when defined(windows):
    proc hostname*(): string =
        getHostname()