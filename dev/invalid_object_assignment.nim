# Apparently this requires true ref objects,
# shallow semantics are not enough.

when false:
  type
    Column* = object of RootObj
      typeInfo*: pointer

    Data* {.shallow.} [T] = object of Column
      data*: seq[T]


  proc toTypeless*[T](c: Data[T]): Column =
    #c

    #let x: Column = c
    #return x

    result = cast[Column](c)

  let a = Data[int]()
  let b = a.toTypeless

when true:
  type
    Base* = object of RootObj
    Sub* = object of Base

  proc toBase*(x: Sub): Base =
    x

  let a = Sub()
  let base1: Base = cast[Base](a)
