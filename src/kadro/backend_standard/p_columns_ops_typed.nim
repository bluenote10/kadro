import sugar
import sequtils
import strutils
import typetraits
import math
import macros
import lenientops
# import threadpool
import tensor/backend/openmp

# import arraymancer # for toTensor

import p_columns_datatypes
import p_columns_constructors
import p_columns_methods
import p_utils


# -----------------------------------------------------------------------------
# Iterators
# -----------------------------------------------------------------------------

iterator items*[T](c: TypedCol[T]): T =
  for x in items(c.data):
    yield x

iterator enumerate*[T](c: TypedCol[T]): (int, T) =
  var i = 0
  for x in items(c.data):
    yield (i, x)
    inc i


# -----------------------------------------------------------------------------
# Conversion
# -----------------------------------------------------------------------------

proc toTypeless*[T](c: TypedCol[T]): Column =
  ## Converts a typed column into an untyped column.
  c

proc toSequence*[T](c: TypedCol[T]): seq[T] =
  ## https://github.com/nim-lang/Nim/issues/7322
  c.data

# temporarily deactivated to speed up compilation
# maybe move into separate extension module
# proc toTensor*[T](c: TypedCol[T]): Tensor[T] =
#   c.data.toTensor

# -----------------------------------------------------------------------------
# Unary operations
# -----------------------------------------------------------------------------

proc sin*(c: TypedCol[SomeNumber], inPlace: static[bool] = false): TypedCol[float] =
  when inPlace:
    {.error: "TypeCol needs to be a var for in place operation".}
  else:
    result = newTypedCol[float](c.len)
    for i, x in c.data:
      result.data[i] = math.sin(x.float)

proc sin*(c: var TypedCol[SomeNumber], inPlace: static[bool] = false): TypedCol[float] =
  when inPlace:
    for i, x in c.data:
      c.data[i] = math.sin(x.float)
      return c
  else:
    result = newTypedCol[float](c.len)
    for i, x in c.data:
      result.data[i] = math.sin(x.float)
      

# -----------------------------------------------------------------------------
# Aggregations
# -----------------------------------------------------------------------------

proc sum*[T](c: TypedCol[T], R: typedesc = float): R =
  # Required because of: https://github.com/nim-lang/Nim/issues/8403
  type RR = R
  var sum: R = 0
  for x in c.data:
    sum += RR(x)
  return sum

#[
# Should no longer be required: https://github.com/nim-lang/Nim/issues/7516
proc sum*[T](c: TypedCol[T]): float =
  c.sum(float)
]#

proc maxNaive*[T](c: TypedCol[T]): T =
  if c.len == 0:
    return T(0)
  else:
    var curMax = low(T)
    for i in 0 ..< c.len:
      if c.arr[i] > curMax:
        curMax = c.arr[i]
    return curMax

proc max*[T](c: TypedCol[T]): T =
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


# -----------------------------------------------------------------------------
# Comparison
# -----------------------------------------------------------------------------

proc `==`*[T](c: TypedCol[T], scalar: T): TypedCol[bool] =
  result = newTypedCol[bool](c.len)
  for i in 0 ..< c.len:
    result.data[i] = c.data[i] == scalar

proc `==`*[T, S](a: TypedCol[T], b: TypedCol[S]): TypedCol[bool] =
  result = newTypedCol[bool](a.len)
  for i in 0 ..< a.len:
    result.data[i] = a.data[i] == b.data[i]


