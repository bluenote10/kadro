import options

type
  Mask* = seq[bool]
  Index* = seq[int]

  ColType* {.pure.} = enum
    Standard, ViewMasked, ViewIndexed

  Column* = ref object of RootObj
    typeInfo*: pointer

  TypedCol*[T] = ref object of Column
    data*: seq[T]  # TODO: remove access
    size*: int
    kind: ColType
    mask: Option[Mask]
    index: Option[Index]