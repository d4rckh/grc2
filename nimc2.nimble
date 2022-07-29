# Package

version       = "0.1.0"
author        = "Anonymous"
description   = "a cool c2"
license       = "GPL-2.0-only"
srcDir        = "src"
bin           = @["nimc2"]


# Dependencies

requires "nim >= 1.6.2"
requires "winim >= 3.8.0"
requires "pixie >= 4.4.0"
requires "ws >= 0.5.0"
requires "uuid4 >= 0.9.3"
requires "terminaltables >= 0.1.1"