import options

import p_index
import p_utils

type

  #Mask* = seq[bool]
  #Index* = seq[int]

  ColType* {.pure.} = enum
    Standard, ViewMasked, ViewIndexed

  Column* = object
    data*: DataUntyped
    index*: Index

  DataUntyped* = ref object of RootObj
    typeInfo*: pointer
    index*: Index

  Data*[T] = ref object of DataUntyped
    data*: seq[T]  # TODO: remove access
    size*: int
    kind: ColType
    #mask: Option[Mask]
    #index: Option[Index]


template newDataShallow*[T](s: seq[T]): Data[T] =
  # make sure data access `s` only once to avoid re-evaluation,
  # but avoid temporary let assignment to avoid taking a copy.
  type TT = T # https://github.com/nim-lang/Nim/issues/5926
  var data = Data[TT](
    typeInfo: getTypeInfo(TT),
    index: nil,
  )
  shallowCopy(data.data, s)
  data.size = data.data.len
  data

template newDataShallow*[T](s: seq[T], index: Index): Data[T] =
  # make sure data access `s` only once to avoid re-evaluation,
  # but avoid temporary let assignment to avoid taking a copy.
  type TT = T # https://github.com/nim-lang/Nim/issues/5926
  var data = Data[TT](
    typeInfo: getTypeInfo(TT),
    index: index,
  )
  shallowCopy(data.data, s)
  data.size = data.data.len
  data
