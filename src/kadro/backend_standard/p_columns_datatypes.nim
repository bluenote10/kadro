import options
import p_utils

type
  Index* = ref object of RootObj

  NoIndex* = ref object of Index
  BoolIndex* = ref object of Index
    mask*: seq[bool]
  IntIndex* = ref object of Index
    indices*: seq[int]

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


template newData*[T](data, size, kind): Data[T] =
  Data[T](
    typeInfo: getTypeInfo(T),
    data: data,
    size: size,
    #kind: kind,
  )
