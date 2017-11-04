import future
import sequtils
import strutils
import typetraits
import macros
# import threadpool
import tensor.backend.openmp

import impltype

# TODO: remove after PR merge + next release
proc high(T: typedesc[SomeReal]): T {.used.} = Inf
proc low(T: typedesc[SomeReal]): T {.used.} = NegInf

const impl = getImpl()
const implFeatures = getImplFeatures()

# Would be nice to make the import conditional, but nimsuggest doesn't like it.
import arraymancer
when impl == Impl.Arraymancer:
  import arraymancer

# -----------------------------------------------------------------------------
# Main typedefs
# -----------------------------------------------------------------------------

type
  Column* = ref object of RootObj

  TypedCol*[T] = ref object of Column
    when impl == Impl.Standard:
      arr*: seq[T]
    elif impl == Impl.Arraymancer:
      data: Tensor[T]

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


template assertType*(c: Column, T: typedesc): TypedCol[T] =
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

template assertTypeUnsafe*(c: Column, T: typedesc): TypedCol[T] =
  cast[TypedCol[T]](c)

template toTyped*(newCol: untyped, c: Column, T: typedesc): untyped =
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
