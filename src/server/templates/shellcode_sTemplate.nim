import ../types 

let tmpl* = Template(
  name: "shellcode_s",
  isBinary: true,
  outExtension: "bin",
  build: proc(shellcode: string): string =
    return shellcode

)