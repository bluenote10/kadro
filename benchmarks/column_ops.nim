import os
import strutils
import tables
import times
import strinterp
import typetraits
import future
import macros

import ../src/columns

import arraymancer
#import tensor/aggregate

type
  Benchmark = int -> float


# template to simplify timed execution
template runTimed(body: untyped): float =
  GC_fullCollect()
  let t1 = epochTime()
  body
  let t2 = epochTime()
  let runtime = (t2 - t1) * 1000
  runtime

proc benchmarkZeros[T](N: int): float =
  let runTime = runTimed:
    let col {.used.} = newCol[T](N)
  runTime

proc benchmarkZerosArraymancer[T](N: int): float =
  let runTime = runTimed:
    let col {.used.} = zeros[T](N)
  runTime

proc benchmarkSum[T](N: int): float =
  let col = newCol[T](N)
  let runTime = runTimed:
    let mean {.used.} = col.sum()
  runTime

proc benchmarkSumArraymancer[T](N: int): float =
  let col = zeros[T](N)
  let runTime = runTimed:
    let mean {.used.} = col.sum()
  runTime

proc benchmarkMax[T](N: int): float =
  let col = newCol[T](N)
  let runTime = runTimed:
    let max {.used.} = col.max(T)
  runTime

proc benchmarkMaxArraymancer[T](N: int): float =
  let col = zeros[T](N)
  let runTime = runTimed:
    let max {.used.} = col.max()
  runTime


proc runBenchmarkRepeated(benchmark: Benchmark, label: string, N: int, iterations: int) =
  var runTimeSum = 0.0
  for i in 0 ..< iterations:
    runTimeSum += benchmark(N)
  let avgRunTime = runTimeSum / iterations.float
  # echo label, ": ", runtime
  echo fmt"${label}%-60s ${avgRunTime}%6.3f ms"

macro makeArrayOverTypes(name: untyped): untyped =
  ## Takes a generic function f and returns an array with generic instantiations:
  ## [(f[int16], "int16", (f[int32], "int32"), ...]
  result = newNimNode(nnkBracket)
  let typeSymbols = [
    bindsym"int16", bindsym"int32", bindsym"int64", bindsym"float32", bindsym"float64"
  ]
  for typeName in typeSymbols:
    result.add(newPar(
      newNimNode(nnkBracketExpr).add(name, typeName),
      newStrLitNode($typeName)
    ))
  # echo "result: ", result.repr

proc allBenchmarkZeros(N: int) =
  echo " *** Benchmark: zeros"
  for benchmark, label in makeArrayOverTypes(benchmarkZeros).items():
    runBenchmarkRepeated(benchmark, label, N, 100)
  echo " *** Benchmark: zeros (arraymancer)"
  for benchmark, label in makeArrayOverTypes(benchmarkZerosArraymancer).items():
    runBenchmarkRepeated(benchmark, label, N, 100)

proc allBenchmarkSum(N: int) =
  echo " *** Benchmark: sum"
  for benchmark, label in makeArrayOverTypes(benchmarkSum).items():
    runBenchmarkRepeated(benchmark, label, N, 100)
  echo " *** Benchmark: sum (arraymancer)"
  for benchmark, label in makeArrayOverTypes(benchmarkSumArraymancer).items():
    runBenchmarkRepeated(benchmark, label, N, 100)

proc allBenchmarkMax(N: int) =
  echo " *** Benchmark: max"
  for benchmark, label in makeArrayOverTypes(benchmarkMax).items():
    runBenchmarkRepeated(benchmark, label, N, 100)
  echo " *** Benchmark: max (arraymancer)"
  for benchmark, label in makeArrayOverTypes(benchmarkMaxArraymancer).items():
    runBenchmarkRepeated(benchmark, label, N, 100)


proc main() =
  if paramCount() != 1:
    echo "ERROR: Expected argument N."
    quit(1)
  let N = paramStr(1).parseInt

  allBenchmarkZeros(N)
  allBenchmarkSum(N)
  allBenchmarkMax(N)



when isMainModule:
  main()
