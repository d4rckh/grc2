import ../types

import shellcode_sTemplate as shellcode_s
import winexe_sTemplate as winexe_s

let templates*: seq[Template] = @[
  shellcode_s.tmpl,
  winexe_s.tmpl
]