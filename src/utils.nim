import macros, os

macro importDirectory*(a: static string, b: static string, c: static string): untyped =
  var bracket = newNimNode(nnkBracket)
  for x in walkDir(a, relative=true):
    echo "importing " & $x
    if x.kind == pcFile:
      let split = x.path.splitFile()
      if split.ext == ".nim":
        bracket.add ident(split.name)
  let a = newStmtList(
  newNimNode(nnkImportStmt).add(
    newNimNode(nnkInfix).add(
      ident("/"),
      newNimNode(nnkPrefix).add(
        ident(b),
        ident(c)
      ),
      bracket
      )
  ))
  return a

macro loadCommands*(a: static string): untyped =
  let stmtList = newStmtList()
  echo "hi"
  for x in walkDir(a, relative=true):
    echo "loading command " & $x
    if x.kind == pcFile:
      let split = x.path.splitFile()
      echo split.name
      if split.ext == ".nim":
        stmtList.add(
          newCall(
            newDotExpr(ident("commands"), ident("add")),
            newDotExpr(ident(split.name), ident("cmd"))
          )
        )
  echo stmtList.repr
  return stmtList
