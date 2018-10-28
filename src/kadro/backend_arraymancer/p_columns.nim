import sugar
import sequtils
import strutils
import typetraits
import macros
import lenientops
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
#import tensor.higher_order_applymap
#import tensor.accessors
when impl == Impl.Arraymancer:
  import arraymancer

# -----------------------------------------------------------------------------
# Main typedefs
# -----------------------------------------------------------------------------

type
  Column* = ref object of RootObj

  Data*[T] = ref object of Column
    when impl == Impl.Standard:
      data*: seq[T]
    elif impl == Impl.Arraymancer:
      data*: Tensor[T]

proc newData*[T](size: int): Data[T] =
  # TODO add unitialized variants
  when impl == Impl.Standard:
    Data[T](data: newSeq[T](size))
  elif impl == Impl.Arraymancer:
    Data[T](data: zeros[T](size))

method `$`*(c: Column): string {.base.} =
  raise newException(AssertionError, "`$` of base method should not be called.")

method `$`*[T](c: Data[T]): string =
  let typeName = name(T)
  result = "Data[" & typeName & "](" & $c.data & ")"

method typeName*(c: Column): string {.base.} =
  raise newException(AssertionError, "`typeName` of base method should not be called.")

method typeName*[T](c: Data[T]): string =
  result = name(T)

method len*(c: Column): int {.base.} =
  raise newException(AssertionError, "`len` of base method should not be called.")

method len*[T](c: Data[T]): int =
  when impl == Impl.Standard:
    result = c.data.len
  elif impl == Impl.Arraymancer:
    result = c.data.shape[0]

#[
method get*(c: Column, i: int, T: typedesc) {.base.} =
  raise newException(AssertionError, "`get` of base method should not be called.")

method get*[U, T](c: Data[U], i: int): T =
  T(c.data[i])
]#

proc get*(c: Column, i: int, T: typedesc): T =
  if c of Data[T]:
    result = cast[Data[T]](c).data[i]
  else:
    raise newException(ValueError, "Column is not of type " & name(T))


method getString*(c: Column, i: int): string {.base.} =
  raise newException(AssertionError, "`get` of base method should not be called.")

method getString*[T](c: Data[T], i: int): string =
  $c.data[i]


template assertType*(c: Column, T: typedesc): Data[T] =
  if not (c of Data[T]):
    let pos = instantiationInfo()
    let msg = "Expected column of type [$1], got [$2] at $3:$4" % [
      name(T),
      c.typeName(),
      pos.filename,
      $pos.line,
    ]
    echo msg
    raise newException(ValueError, msg)
  cast[Data[T]](c)

template assertTypeUnsafe*(c: Column, T: typedesc): Data[T] =
  cast[Data[T]](c)

template toTyped*(newCol: untyped, c: Column, T: typedesc): untyped =
  ## Alternative to assertType.
  ## Pro: - The user doesn't have to decide between let or var.
  ## Con: - Doesn't emphasize that there is an assertion.
  if not (c of Data[T]):
    raise newException(ValueError, "Expected column of type " & name(T))
  let newCol = cast[Data[T]](c)

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
    let cond = infix(c, "of", newNimNode(nnkBracketExpr).add(bindSym"Data", t))
    let body = newStmtList()
    body.add(newLetStmt(cTyped, newCall(bindSym"assertTypeUnsafe", c, t)))
    body.add(procBody)
    elifBranch.add(cond)
    elifBranch.add(body)
    result.add(elifBranch)
  result = newStmtList(result)
  echo result.repr

template defaultImpls(c: Column, cTyped: untyped, procBody: untyped): untyped =
  if c of Data[int8]:
    let `cTyped` {.inject.} = c.assertTypeUnsafe(int8)
    procBody
  elif c of Data[int16]:
    let `cTyped` {.inject.} = c.assertTypeUnsafe(int16)
    procBody
  elif c of Data[int32]:
    let `cTyped` {.inject.} = c.assertTypeUnsafe(int32)
    procBody
  elif c of Data[int64]:
    let `cTyped` {.inject.} = c.assertTypeUnsafe(int64)
    procBody
  # FIXME: Do we really need an implementation for int or can we generically
  # apply some casts to any of the other types?
  elif c of Data[int]:
    let `cTyped` {.inject.} = c.assertTypeUnsafe(int)
    procBody
  elif c of Data[float32]:
    let `cTyped` {.inject.} = c.assertTypeUnsafe(float32)
    procBody
  elif c of Data[float64]:
    let `cTyped` {.inject.} = c.assertTypeUnsafe(float64)
    procBody

# -----------------------------------------------------------------------------
# Iterators
# -----------------------------------------------------------------------------

iterator items*[T](c: Data[T]): T =
  for x in items(c.data):
    yield x

iterator enumerate*[T](c: Data[T]): (int, T) =
  var i = 0
  for x in items(c.data):
    yield (i, x)
    inc i

# -----------------------------------------------------------------------------
# Conversion
# -----------------------------------------------------------------------------

proc toTypeless*[T](c: Data[T]): Column = c
  ## Converts a typed column into an untyped column, which can obviously
  ## be auto-casted anyway. The function only exists as a syntactical
  ## convenience internally for unit tests.

proc toSequence*[T](c: Data[T]): seq[T] =
  ## https://github.com/nim-lang/Nim/issues/7322
  when impl == Impl.Standard:
    c.data
  else:
    c.data.toRawSeq

proc toSequence*(c: Column, T: typedesc): seq[T] =
  ## https://github.com/nim-lang/Nim/issues/7322
  c.assertType(T).toSequence()

proc toTensor*[T](c: Data[T]): Tensor[T] =
  when impl == Impl.Standard:
    c.data.toTensor
  else:
    c.data

proc toTensor*(c: Column, T: typedesc): Tensor[T] =
  c.assertType(T).toTensor()

# -----------------------------------------------------------------------------
# Aggregations
# -----------------------------------------------------------------------------

#[
# FIXME: Why doesn't this work with a typedesc?
proc sum*[T](c: Data[T], R: typedesc): R =
  var sum: R = 0
  for x in c.data:
    sum += R(x) # typedesc can't be used as type conversion?
  return sum
]#

proc sumGeneric*[T, R](c: Data[T]): R =
  ## Most generic implementation of a sum, where the result type is generic
  ## as well.
  # FIXME: Why can I not call it `sum`?
  var sum = R(0)
  for x in c.data:
    sum += R(x)
  return sum

proc sum*[T](c: Data[T]): float =
  when impl == Impl.Standard:
    # c.sum(float)
    sumGeneric[T, float](c)
  elif impl == Impl.Arraymancer:
    # FIXME: How to deal with overflows?
    c.data.sum().float

#[
proc sum*(c: Column): float =
  multiImpl(c, cTyped, [int16, int32, int64, float32, float64]):
    return cTyped.sum()
]#

proc sum*(c: Column): float =
  defaultImpls(c, cTyped):
    return cTyped.sum()
  raise newException(ValueError, "sum not implemented for type: " & c.typeName())

proc mean*(c: Column): float =
  c.sum() / c.len.float

proc maxNaive*[T](c: Data[T]): T =
  if c.len == 0:
    return T(0)
  else:
    var curMax = low(T)
    for i in 0 ..< c.len:
      if c.arr[i] > curMax:
        curMax = c.arr[i]
    return curMax

proc max*[T](c: Data[T]): T =
  when impl == Impl.Standard:
    # Optimized implementation. Seems to be faster for larger types (64 bit)
    # but slower for smaller types (16 bit)
    if c.len == 0:
      return low(T)
    else:
      var curMax = low(T)
      var i = 0
      let nTwoAligned = (c.len shr 1 shl 1)
      while i < nTwoAligned:
        let localMax = if c.data[i] > c.data[i+1]: c.data[i] else: c.data[i+1]
        if localMax > curMax:
          curMax = localMax
        i += 2
      if i < c.len - 1:
        if c.data[^1] > curMax:
          curMax = c.data[^1]
      return curMax
  elif impl == Impl.Arraymancer:
    return c.data.max()

proc max*(c: Column, T: typedesc): T =
  let cTyped = c.assertType(T)
  return cTyped.max()

proc max*(c: Column): float =
  defaultImpls(c, cTyped):
    return cTyped.max().float
  raise newException(ValueError, "max not implemented for type: " & c.typeName())

# -----------------------------------------------------------------------------
# Comparison
# -----------------------------------------------------------------------------

proc `==`*[T](c: Data[T], scalar: T): Data[bool] =
  when impl == Impl.Standard:
    result = newData[bool](c.len)
    for i in 0 ..< c.len:
      result.data[i] = c.data[i] == scalar
  elif impl == Impl.Arraymancer:
    result = Data[bool](data: c.data.map_inline(x == scalar))

proc `==`*[T, S](a: Data[T], b: Data[S]): Data[bool] =
  when impl == Impl.Standard:
    result = newData[bool](c.len)
    for i in 0 ..< c.len:
      result.data[i] = a.data[i] == b.data[i]
  elif impl == Impl.Arraymancer:
    result = Data[bool](data: map2_inline(a.data, b.data, x == y))
