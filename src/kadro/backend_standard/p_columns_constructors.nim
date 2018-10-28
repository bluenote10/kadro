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

proc newData*[T](size: int): Data[T] =
  Data[T](
    typeInfo: getTypeInfo(T),
    data: newSeq[T](size),
    size: size,
  )


proc newDataUninit*[T](size: int): Data[T] =
  Data[T](
    typeInfo: getTypeInfo(T),
    data: newSeqUninitialized[T](size),
    size: size,
  )

#[
proc newDataMasked*[T](data: seq[T], mask: Mask): Data[T] =
  Data[T](
    typeInfo: getTypeInfo(T),
    data: data,
    mask: some(mask),
  )
]#


proc toData*[T](s: openarray[T]): Data[T] =
  return Data[T](
    typeInfo: getTypeInfo(T),
    data: @s,
    size: s.len,
  )


proc toUntyped*[T](s: openarray[T]): DataUntyped =
  return Data[T](
    typeInfo: getTypeInfo(T),
    data: @s,
    size: s.len,
  )

proc toColumn*[T](s: openarray[T]): Column =
  return Column(
    data: s.toUntyped
  )


proc copy*[T](c: Data[T]): Data[T] =
  return Data[T](
    typeInfo: c.typeInfo,
    data: c.data,
    size: c.size,
  )


# -----------------------------------------------------------------------------
# Secondary constructors
# -----------------------------------------------------------------------------

proc zeros*[T](length: int): Data[T] =
  var Data = newDataUninit[T](length)
  when ImplFeature.OpenMP notin implFeatures:
    #for i in 0 ..< length:
    #  Data.data[i] = T(0)
    # TODO check types for which memset is valid
    zeroMem(Data.data[0].addr, length * sizeOf(T))
  else:
    omp_parallel_countup(i, length):
      Data.data[i] = T(0)
  return Data


proc ones*[T](length: int): Data[T] =
  var Data = newDataUninit[T](length)
  when ImplFeature.OpenMP notin implFeatures:
    for i in 0 ..< length:
      Data.data[i] = T(1)
  else:
    omp_parallel_countup(i, length):
      Data.data[i] = T(1)
  return Data


proc arange*[T](length: int): Data[T] =
  var Data = newDataUninit[T](length)
  when ImplFeature.OpenMP notin implFeatures:
    for i in 0 ..< length:
      Data.data[i] = T(i)
  else:
    omp_parallel_countup(i, length):
      Data.data[i] = T(i)
  return Data
