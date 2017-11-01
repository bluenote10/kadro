import os
import strutils
import sequtils
import tables
import times
import strinterp
import typetraits
import future
import macros

import ../src/columns

import arraymancer

type
  Benchmark = object
    f: int -> float
    dtype: string

proc newBenchmark(f: int -> float, dtype: string): Benchmark =
  Benchmark(f: f, dtype: dtype)

# template to simplify timed execution
template runTimed(body: untyped): float =
  GC_fullCollect()
  let t1 = epochTime()
  body
  let t2 = epochTime()
  let runtime = (t2 - t1) * 1000
  runtime

# -----------------------------------------------------------------------------
# Benchmarks
# -----------------------------------------------------------------------------

proc benchmarkZeros[T](N: int): float =
  let runTime = runTimed:
    let col {.used.} = zeros[T](N)
  runTime

proc benchmarkOnes[T](N: int): float =
  let runTime = runTimed:
    let col {.used.} = ones[T](N)
  runTime

proc benchmarkRange[T](N: int): float =
  let runTime = runTimed:
    let col {.used.} = range[T](N)
  runTime

proc benchmarkSum[T](N: int): float =
  let col = zeros[T](N)
  let runTime = runTimed:
    let mean {.used.} = col.sum()
  runTime

proc benchmarkMax[T](N: int): float =
  let col = zeros[T](N)
  let runTime = runTimed:
    let max {.used.} = col.max(T)
  runTime

# -----------------------------------------------------------------------------
# Runner helpers
# -----------------------------------------------------------------------------

proc runBenchmarkRepeated(benchmark: Benchmark, N: int, iterations: int): seq[float] =
  var runtimeSum = 0.0
  var runtimeMin = Inf
  var runtimeMax = NegInf
  var allRuntimes = newSeq[float](iterations)
  for i in 0 ..< iterations:
    let runtime = benchmark.f(N)
    allRuntimes[i] = runtime
    runtimeSum += runtime
    if runtime < runtimeMin:
      runtimeMin = runtime
    if runtime > runtimeMax:
      runtimeMax = runtime
  let runtimeAvg = runtimeSum / iterations.float
  echo fmt"${benchmark.dtype}%-60s ${runtimeMin}%6.3f ms    ${runtimeAvg}%6.3f ms    ${runtimeMax}%6.3f ms"
  return allRuntimes

macro makeArrayOverTypes(name: untyped): untyped =
  ## Takes a generic function f and returns an array with benchmark
  ## instances.
  result = newNimNode(nnkBracket)
  let typeSymbols = [
    bindsym"int16", bindsym"int32", bindsym"int64", bindsym"float32", bindsym"float64"
  ]
  for typeName in typeSymbols:
    result.add(newCall(
      bindSym"newBenchmark",
      newNimNode(nnkBracketExpr).add(name, typeName),
      newStrLitNode($typeName)
    ))
  echo "result: ", result.repr

proc runAllBenchmarks(label: string, N: int, benchmarks: openarray[Benchmark]) =
  echo fmt" *** Benchmark: $label"
  let outputFile = open(fmt"results/result_${N}_kadro_${label}.csv", fmWrite)
  for benchmark in benchmarks:
    let runtimes = runBenchmarkRepeated(benchmark, N, 100)
    outputFile.write(benchmark.dtype & ";")
    outputFile.writeLine(runtimes.map(x => $x).join("; "))
  outputFile.close()

proc main() =
  let args = commandLineParams()
  if args.len == 0:
    echo "ERROR: Expected argument N."
    quit(1)
  let N = args[0].parseInt
  let selection = if args.len > 1: args[1] else: nil

  if selection.isNil or selection == "zeros":
    runAllBenchmarks("zeros", N, makeArrayOverTypes(benchmarkZeros))
  if selection.isNil or selection == "ones":
    runAllBenchmarks("ones", N, makeArrayOverTypes(benchmarkZeros))
  if selection.isNil or selection == "range":
    runAllBenchmarks("range", N, makeArrayOverTypes(benchmarkZeros))
  if selection.isNil or selection == "sum":
    runAllBenchmarks("sum", N, makeArrayOverTypes(benchmarkSum))
  if selection.isNil or selection == "max":
    runAllBenchmarks("max", N, makeArrayOverTypes(benchmarkMax))



when isMainModule:

  main()
