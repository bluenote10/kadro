import options

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

  Column* = ref object of RootObj
    typeInfo*: pointer
    index*: Index

  TypedCol*[T] = ref object of Column
    data*: seq[T]  # TODO: remove access
    size*: int
    kind: ColType
    #mask: Option[Mask]
    #index: Option[Index]

