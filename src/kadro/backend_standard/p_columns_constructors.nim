import sugar
import sequtils
import strutils
import typetraits
import macros
import lenientops
import options

import tensor/backend/openmp

import p_columns_datatypes
import p_utils

import ../impltype
const implFeatures = getImplFeatures()


# -----------------------------------------------------------------------------
# Base constructors
# -----------------------------------------------------------------------------

proc newTypedCol*[T](size: int): TypedCol[T] =
  TypedCol[T](
    typeInfo: getTypeInfo(T),
    data: newSeq[T](size),
    size: size,
  )


proc newTypedColUninit*[T](size: int): TypedCol[T] =
  TypedCol[T](
    typeInfo: getTypeInfo(T),
    data: newSeqUninitialized[T](size),
    size: size,
  )


proc newTypedColMasked*[T](data: seq[T], mask: Mask): TypedCol[T] =
  TypedCol[T](
    typeInfo: getTypeInfo(T),
    data: data,
    mask: some(mask),
  )


proc toColumn*[T](s: openarray[T]): TypedCol[T] =
  return TypedCol[T](
    typeInfo: getTypeInfo(T),
    data: @s,
    size: s.len,
  )


proc copy*[T](c: TypedCol[T]): TypedCol[T] =
  return TypedCol[T](
    typeInfo: c.typeInfo,
    data: c.data,
    size: c.size,
  )


# -----------------------------------------------------------------------------
# Secondary constructors
# -----------------------------------------------------------------------------

proc zeros*[T](length: int): TypedCol[T] =
  var typedCol = newTypedColUninit[T](length)
  when ImplFeature.OpenMP notin implFeatures:
    #for i in 0 ..< length:
    #  typedCol.data[i] = T(0)
    # TODO check types for which memset is valid
    zeroMem(typedCol.data[0].addr, length * sizeOf(T))
  else:
    omp_parallel_countup(i, length):
      typedCol.data[i] = T(0)
  return typedCol


proc ones*[T](length: int): TypedCol[T] =
  var typedCol = newTypedColUninit[T](length)
  when ImplFeature.OpenMP notin implFeatures:
    for i in 0 ..< length:
      typedCol.data[i] = T(1)
  else:
    omp_parallel_countup(i, length):
      typedCol.data[i] = T(1)
  return typedCol


proc arange*[T](length: int): TypedCol[T] =
  var typedCol = newTypedColUninit[T](length)
  when ImplFeature.OpenMP notin implFeatures:
    for i in 0 ..< length:
      typedCol.data[i] = T(i)
  else:
    omp_parallel_countup(i, length):
      typedCol.data[i] = T(i)
  return typedCol
