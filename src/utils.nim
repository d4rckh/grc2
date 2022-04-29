import macros, os

macro importCommands*(): untyped =
    var bracket = newNimNode(nnkBracket)
    for x in walkDir("src/commands", relative=true):
        echo x
        if x.kind == pcFile:
            let split = x.path.splitFile()
            if split.ext == ".nim":
                bracket.add ident(split.name)
    let a = newStmtList(
    newNimNode(nnkImportStmt).add(
      newNimNode(nnkInfix).add(
        ident("/"),
        newNimNode(nnkPrefix).add(
          ident("./"),
          ident("commands")
        ),
        bracket
        )
    ))
    return a