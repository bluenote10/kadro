import os
import strutils
import tables
import times
import strinterp
import typetraits

import ../src/columns

import arraymancer

# template to simplify timed execution
template runTimed(label, body: untyped) =
  let t1 = epochTime()
  let iter = 1000
  GC_fullCollect()
  for i in 1 .. iter:
    body
  let t2 = epochTime()
  let runtime {.inject.} = (t2 - t1) * 1000 / iter.float
  # echo label, ": ", runtime
  let localLabel {.inject.} = label
  echo fmt"${localLabel}%-60s ${runtime}%6.3f ms"

proc benchmarkZeros[T](N: int) =
  runTimed name(T):
    let col {.used.} = newCol[T](N)

proc benchmarkZerosArraymancer[T](N: int) =
  runTimed name(T):
    let col {.used.} = zeros([N], T)

proc benchmarkSum[T](N: int) =
  let col = newCol[T](N)
  runTimed name(T):
    let mean {.used.} = col.sum()

proc benchmarkSumArraymancer[T](N: int) =
  let col = zeros([N], T)
  runTimed name(T):
    let mean {.used.} = col.sum()


proc main() =
  if paramCount() != 1:
    echo "ERROR: Expected argument N."
    quit(1)
  let N = paramStr(1).parseInt

  echo " *** Benchmark: zeros"
  benchmarkZeros[int16](N)
  benchmarkZeros[int32](N)
  benchmarkZeros[int64](N)
  benchmarkZeros[float32](N)
  benchmarkZeros[float64](N)

  echo " *** Benchmark: zeros (arraymancer)"
  benchmarkZerosArraymancer[int16](N)
  benchmarkZerosArraymancer[int32](N)
  benchmarkZerosArraymancer[int64](N)
  benchmarkZerosArraymancer[float32](N)
  benchmarkZerosArraymancer[float64](N)

  echo " *** Benchmark: sum"
  benchmarkSum[int16](N)
  #benchmarkSum[int32](N)
  #benchmarkSum[int64](N)
  benchmarkSum[float32](N)
  #benchmarkSum[float64](N)

  echo " *** Benchmark: sum (arraymancer)"
  benchmarkSumArraymancer[int16](N)
  benchmarkSumArraymancer[int32](N)
  benchmarkSumArraymancer[int64](N)
  benchmarkSumArraymancer[float32](N)
  benchmarkSumArraymancer[float64](N)


when isMainModule:
  main()
