import options

type
  Mask = seq[bool]

  ColType {.pure.} = enum
    Standard, View

  Column* = ref object of RootObj
    typeInfo*: pointer

  TypedCol*[T] = ref object of Column
    data*: seq[T]  # TODO: remove access
    kind: ColType
    mask: Option[Mask]