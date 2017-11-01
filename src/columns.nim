import future
import sequtils
import strutils
import typetraits
import macros
# import threadpool

import tensor.backend.openmp

proc high(T: typedesc[SomeReal]): T {.used.} = Inf
proc low(T: typedesc[SomeReal]): T {.used.} = NegInf

# -----------------------------------------------------------------------------
# Main typedefs
# -----------------------------------------------------------------------------

type
  Column* = ref object of RootObj

  TypedCol*[T] = ref object of Column
    arr*: seq[T]

method `$`*(c: Column): string {.base.} =
  raise newException(AssertionError, "`$` of base method should not be called.")

method `$`*[T](c: TypedCol[T]): string =
  let typeName = name(T)
  result = "TypedCol[" & typeName & "](" & $c.arr & ")"

method `typeName`*(c: Column): string {.base.} =
  raise newException(AssertionError, "`typeName` of base method should not be called.")

method `typeName`*[T](c: TypedCol[T]): string =
  result = name(T)

method `len`*(c: Column): int {.base.} =
  raise newException(AssertionError, "`len` of base method should not be called.")

method `len`*[T](c: TypedCol[T]): int =
  result = c.arr.len


proc newCol*[T](s: seq[T]): Column =
  return TypedCol[T](arr: s)

proc zeros*[T](length: int): Column =
  let typedCol = TypedCol[T](arr: newSeqOfCap[T](length))
  typedCol.arr.setLen(length)
  #for i in 0 ..< length:
  #  typedCol.arr[i] = T(0)
  omp_parallel_countup(i, length):
    typedCol.arr[i] = T(0)
  return typedCol

proc ones*[T](length: int): Column =
  let typedCol = TypedCol[T](arr: newSeqOfCap[T](length))
  typedCol.arr.setLen(length)
  #for i in 0 ..< length:
  #  typedCol.arr[i] = T(0)
  omp_parallel_countup(i, length):
    typedCol.arr[i] = T(1)
  return typedCol

proc range*[T](length: int): Column =
  let typedCol = TypedCol[T](arr: newSeqOfCap[T](length))
  typedCol.arr.setLen(length)
  #for i in 0 ..< length:
  #  typedCol.arr[i] = T(0)
  omp_parallel_countup(i, length):
    typedCol.arr[i] = i
  return typedCol


template assertType(c: Column, T: typedesc): TypedCol[T] =
  if not (c of TypedCol[T]):
    let pos = instantiationInfo()
    let msg = "Expected column of type [$1], got [$2] at $3:$4" % [
      name(T),
      c.typeName(),
      pos.filename,
      $pos.line,
    ]
    echo msg
    raise newException(ValueError, msg)
  cast[TypedCol[T]](c)

template assertTypeUnsafe(c: Column, T: typedesc): TypedCol[T] =
  cast[TypedCol[T]](c)

template toTyped(newCol: untyped, c: Column, T: typedesc): untyped =
  ## Alternative to assertType.
  ## Pro: - The user doesn't have to decide between let or var.
  ## Con: - Doesn't emphasize that there is an assertion.
  if not (c of TypedCol[T]):
    raise newException(ValueError, "Expected column of type " & name(T))
  let newCol = cast[TypedCol[T]](c)

# -----------------------------------------------------------------------------
# Macro helpers
# -----------------------------------------------------------------------------

macro multiImpl(c: Column, cTyped: untyped, types: untyped, procBody: untyped): untyped =
  echo c.treeRepr
  echo types.treeRepr
  echo procBody.treeRepr
  result = newIfStmt()
  for t in types:
    echo t.treeRepr
    let elifBranch = newNimNode(nnkElifBranch)
    let cond = infix(c, "of", newNimNode(nnkBracketExpr).add(bindSym"TypedCol", t))
    let body = newStmtList()
    body.add(newLetStmt(cTyped, newCall(bindSym"assertTypeUnsafe", c, t)))
    body.add(procBody)
    elifBranch.add(cond)
    elifBranch.add(body)
    result.add(elifBranch)
  result = newStmtList(result)
  echo result.repr

template defaultImpls(c: Column, cTyped: untyped, procBody: untyped): untyped =
  if c of TypedCol[int8]:
    let `cTyped` {.inject.} = c.assertTypeUnsafe(int8)
    procBody
  elif c of TypedCol[int16]:
    let `cTyped` {.inject.} = c.assertTypeUnsafe(int16)
    procBody
  elif c of TypedCol[int32]:
    let `cTyped` {.inject.} = c.assertTypeUnsafe(int32)
    procBody
  elif c of TypedCol[int64]:
    let `cTyped` {.inject.} = c.assertTypeUnsafe(int64)
    procBody
  elif c of TypedCol[float32]:
    let `cTyped` {.inject.} = c.assertTypeUnsafe(float32)
    procBody
  elif c of TypedCol[float64]:
    let `cTyped` {.inject.} = c.assertTypeUnsafe(float64)
    procBody


# -----------------------------------------------------------------------------
# Aggregations
# -----------------------------------------------------------------------------

proc sum*[T](c: TypedCol[T]): float =
  var sum = 0.0
  for x in c.arr:
    sum += x.float
  return sum

proc sumExplicit(c: Column): float =
  if c of TypedCol[int]:
    let cTyped = c.assertType(int)
    return cTyped.sum()
  elif c of TypedCol[float32]:
    let cTyped = c.assertType(float32)
    return cTyped.sum()
  elif c of TypedCol[float64]:
    let cTyped = c.assertType(float64)
    return cTyped.sum()
  else:
    raise newException(ValueError, "sum not implemented for type: " & c.typeName())

#[
proc sum*(c: Column): float =
  multiImpl(c, cTyped, [int16, int32, int64, float32, float64]):
    return cTyped.sum()
]#

proc sum*(c: Column): float =
  defaultImpls(c, cTyped):
    return cTyped.sum()
  raise newException(ValueError, "sum not implemented for type: " & c.typeName())

proc mean*[T](c: TypedCol[T]): float =
  c.sum() / c.len.float

proc mean*(c: Column): float =
  c.sum() / c.len.float

proc max*[T](c: TypedCol[T]): T =
  if c.len == 0:
    return T(0)
  else:
    var curMax = low(T)
    for i in 0 ..< c.len:
      if c.arr[i] > curMax:
        curMax = c.arr[i]
    return curMax

proc maxAlternative*[T](c: TypedCol[T]): T =
  ## Optimized implementation. Seems to be faster for larger types (64 bit)
  ## but slower for smaller types (16 bit)
  if c.len == 0:
    return low(T)
  else:
    var curMax = low(T)
    var i = 0
    let nTwoAligned = (c.len shr 1 shl 1)
    while i < nTwoAligned:
      let localMax = if c.arr[i] > c.arr[i+1]: c.arr[i] else: c.arr[i+1]
      if localMax > curMax:
        curMax = localMax
      i += 2
    if i < c.len - 1:
      if c.arr[^1] > curMax:
        curMax = c.arr[^1]
    return curMax

proc max*(c: Column, T: typedesc): T =
  let cTyped = c.assertType(T)
  return cTyped.maxAlternative()

proc max*(c: Column): float =
  defaultImpls(c, cTyped):
    return cTyped.maxAlternative().float
  raise newException(ValueError, "max not implemented for type: " & c.typeName())


when isMainModule:
  proc genDynamicCol(s: string): Column =
    case s
    of "string":
      return newCol(@["1", "2", "3"])
    of "int":
      return newCol(@[1, 2, 3])

  proc operateOnCol(c: Column) =
    if c of TypedCol[string]:
      let cTyped = cast[TypedCol[string]](c)
      echo "string column": cTyped.arr
    elif c of TypedCol[int]:
      let cTyped = cast[TypedCol[int]](c)
      echo "int column": cTyped.arr
    else:
      echo "can't match type"

  let c1 = genDynamicCol("string")
  let c2 = genDynamicCol("int")

  echo c1
  echo c2
  operateOnCol(c1)
  operateOnCol(c2)

  block:  # block allows to re-use variable names
    let c1 = c1.assertType(string)
    let c2 = c2.assertType(int)
    echo c1.arr
    echo c2.arr

  block:  # block allows to re-use variable names
    toTyped(c1, c1, string)
    toTyped(c2, c2, int)
    echo c1.arr
    echo c2.arr