import noise, strutils, terminal

proc main() =
  var noise = Noise.init()
  
  let prompt = Styler.init(fgRed, "Red ", fgGreen, "苹果> ")
  noise.setPrompt(prompt)

  when promptPreloadBuffer:
    noise.preloadBuffer("Superman")

  when promptHistory:
    var file = "history"
    discard noise.historyLoad(file)

  when promptCompletion:
    proc completionHook(noise: var Noise, text: string): int =
      const words = ["apple", "diamond", "diadem", "diablo", "horse", "home", "quartz", "quit"]
      for w in words:
        if w.find(text) != -1:
          noise.addCompletion w

    noise.setCompletionHook(completionHook)

  while true:
    let ok = noise.readLine()
    if not ok: break

    let line = noise.getLine
    case line
    of ".help": echo "help"
    of ".quit": break
    else: discard

    when promptHistory:
      if line.len > 0:
        noise.historyAdd(line)

  when promptHistory:
    discard noise.historySave(file)

main()
