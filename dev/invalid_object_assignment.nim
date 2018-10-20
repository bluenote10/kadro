# Apparently this requires true ref objects,
# shallow semantics are not enough.

type
  Column* = object of RootObj
    typeInfo*: pointer

  TypedCol* {.shallow.} [T] = object of Column
    data*: seq[T]


proc toTypeless*[T](c: TypedCol[T]): Column =
  #c

  #let x: Column = c
  #return x

  result = cast[Column](c)

let a = TypedCol[int]()
let b = a.toTypeless