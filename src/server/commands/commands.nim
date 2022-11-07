import ../types

import interactCommands/[
  # downloadCmd,
  infoCmd,
  # injectShellcodeCmd,
  # msgboxCmd,
  # processesCmd,
  # sendtaskCmd,
  shellCmd,
  dirCmd,
  # tokeninfoCmd,
  uploadCmd,
  # sleepCmd,
  # enumtasksCmd,
  # antivirusesCmd
]

import mainCommands/[
  backCmd,
  clearCmd,
  clientsCmd,
  exitCmd,
  generateimplantCmd,
  helpCmd,
  interactCmd,
  listenersCmd,
  lootCmd,
  startlistenerCmd,
  stoplistenerCmd,
  tasksCmd,
  viewtaskCmd
]

let commands*: seq[Command] = @[
  # downloadCmd.cmd,
  infoCmd.cmd,
  # injectShellcodeCmd.cmd,
  # msgboxCmd.cmd,
  # processesCmd.cmd,
  # sendtaskCmd.cmd,
  shellCmd.cmd,
  dirCmd.cmd,
  # tokeninfoCmd.cmd,
  uploadCmd.cmd,
  # sleepCmd.cmd,
  # enumtasksCmd.cmd,
  # antivirusesCmd.cmd,

  backCmd.cmd,
  clearCmd.cmd,
  clientsCmd.cmd,
  exitCmd.cmd,
  generateimplantCmd.cmd,
  helpCmd.cmd,
  interactCmd.cmd,
  listenersCmd.cmd,
  lootCmd.cmd,
  startlistenerCmd.cmd,
  stoplistenerCmd.cmd,
  tasksCmd.cmd,
  viewtaskCmd.cmd
]