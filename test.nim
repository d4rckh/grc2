import std/json

let myJson = %*{}

for key, val in pairs(myJson["data"]):
  echo key, val

echo "hi"