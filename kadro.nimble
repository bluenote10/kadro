# Package

version       = "0.1.0"
author        = "Fabian Keller"
description   = "Experiments towards dynamically typed DataFrames."
license       = "MIT"

# Dependencies

srcDir = "src"

requires "nim >= 0.17.1"
requires "arraymancer#head"

task test, "Runs unit tests":
  exec "nim c -r tests/tester.nim"

task benchmark, "Runs benchmark":
  cd "benchmarks"
  #exec "nim c -r -d:release -d:openmp --cc:gcc column_ops.nim 10000000"
  exec "nim c -r -d:release column_ops.nim 10000000"

task docs, "Generates docs":
  exec "nim doc2 --project --docSeeSrcUrl:https://github.com/bluenote10/kadro/blob/master -o:./docs/ src/kadro.nim"