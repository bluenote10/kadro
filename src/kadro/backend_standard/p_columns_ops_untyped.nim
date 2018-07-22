import sugar
import sequtils
import strutils
import typetraits
import macros
import lenientops
import tables

import tensor.backend.openmp
import arraymancer # for toTensor

import p_columns_datatypes
import p_columns_constructors
import p_columns_ops_typed
import p_utils


# -----------------------------------------------------------------------------
# Conversion
# -----------------------------------------------------------------------------

proc toSequence*(c: Column, T: typedesc): seq[T] =
  ## https://github.com/nim-lang/Nim/issues/7322
  c.assertType(T).toSequence()

proc toTensor*(c: Column, T: typedesc): Tensor[T] =
  c.assertType(T).toTensor()


# -----------------------------------------------------------------------------
# Type casts
# -----------------------------------------------------------------------------

template assertType*(c: Column, T: typedesc): TypedCol[T] =
  if not (c of TypedCol[T]):
    let pos = instantiationInfo()
    let msg = "Expected column of type [$1], got [$2] at $3:$4" % [
      name(T),
      c.typeName(),
      pos.filename,
      $pos.line,
    ]
    raise newException(ValueError, msg)
  cast[TypedCol[T]](c)

template assertTypeUnsafe*(c: Column, T: typedesc): TypedCol[T] =
  cast[TypedCol[T]](c)


# -----------------------------------------------------------------------------
# Generic getters
# -----------------------------------------------------------------------------

#[
method get*(c: Column, i: int, T: typedesc) {.base.} =
  raise newException(AssertionError, "`get` of base method should not be called.")

method get*[U, T](c: TypedCol[U], i: int): T =
  T(c.data[i])
]#

proc get*(c: Column, i: int, T: typedesc): T =
  if c of TypedCol[T]:
    result = cast[TypedCol[T]](c).data[i]
  else:
    raise newException(ValueError, "Column is not of type " & name(T))


# -----------------------------------------------------------------------------
# Aggregations
# -----------------------------------------------------------------------------

var registeredSumProcs = initTable[pointer, Column -> float]()

template registerSingleColumnType*(T: typedesc) =
  let ti = getTypeInfo(T)
  echo "registering single column ops for typeInfo: ", ti.repr[0..^2]

  proc sum_impl*(c: Column): float {.gensym.} =
    let cTyped = c.assertType(T)
    cTyped.sum()

  registeredSumProcs[ti] = sum_impl

proc sum*(c: Column): float =
  let ti = c.typeInfo
  let f = registeredSumProcs[ti]
  f(c)

proc mean*(c: Column): float =
  c.sum() / c.len


# -----------------------------------------------------------------------------
# Comparison (untyped)
# -----------------------------------------------------------------------------

proc `==`*[T](c: Column, scalar: T): TypedCol[bool] =
  result = newTypedCol[bool](c.len)
  let cTyped = c.assertType(T)
  # TODO: it would be nice if we had a `assertTypeOrConvertableTo(T)`
  for i in 0 ..< c.len:
    result.data[i] = cTyped.data[i] == scalar


when not defined(noDefaultRegistration):
  registerSingleColumnType(int)
  registerSingleColumnType(int8)
  registerSingleColumnType(float)
