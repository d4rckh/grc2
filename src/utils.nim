import uuid4

proc rndStr*: string =
  return $uuid4()
