import terminal

import types

proc infoLog*(msg: string) =
    stdout.styledWriteLine fgBlue, "[!] ", msg, fgWhite

proc cConnected*(client: Client) =
    stdout.styledWriteLine fgGreen, "[+] ", $client, " connected", fgWhite

proc cDisconnected*(client: Client) =
    stdout.styledWriteLine fgRed, "[-] ", $client, " disconnected", fgWhite