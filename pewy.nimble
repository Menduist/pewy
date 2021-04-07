# Package

version       = "0.1.0"
author        = "Tanguy"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
bin           = @["pewy"]


# Dependencies

requires "nim >= 1.4.4"
requires "nimgl >= 1.0.0"
requires "jsbind >= 0.1.1"
requires "nimPNG >= 0.3.1"
requires "nimBMP >= 0.1.8"
requires "glm >= 1.1.1"

task web, "build web version":
  switch("define", "wasm")
  bin = @["pewy.html"]
  setCommand "build"
