import ../types, ../logging

import std/[strutils, os, osproc]

let tmpl* = Template(
  name: "winexe_s",
  isBinary: true,
  outExtension: "exe",
  build: proc(shellcode: string): string =
    let byteArray = cast[seq[byte]](shellcode)

    var c_char_array = "\""

    var i = 1
    for byt in byteArray:
      c_char_array &= "\\x" & toHex(byt)
      if i mod 16 == 0:
        c_char_array &= "\"\n\""
      inc i

    if c_char_array[c_char_array.len() - 1] != '"':
      c_char_array &= "\""

    if not fileExists("src/server/templates/winexe_s.c"):
      errorLog "couldn't find winexe_s.c at src/server/templates/winexe_s.c"
      return ""

    let c_template = readFile("src/server/templates/winexe_s.c").replace("\"\\x00\\x00\\x00\\x00\"", c_char_array)    

    writeFile("_temp.c", c_template)

    var cmdOut = 1

    when defined(windows):
      cmdOut = execCmd("gcc -s _temp.c")
    else:
      cmdOut = execCmd("x86_64-w64-mingw32-gcc -s _temp.c")

    if cmdOut == 0:
      let exe_bin = readFile("a.exe")
      # clean up
      removeFile("a.exe")
      removeFile("_temp.c")
      return exe_bin
    else:
      errorLog "error compiling with gcc. is it in path?"
      removeFile("_temp.c")
      return ""
)