
import typetraits

type
  Column* = ref object of RootObj

  Data*[T] = ref object of Column
    data*: seq[T]


method getInt*(c: Column, i: int): int {.base.} =
  raise newException(AssertionError, "abstract base method called")

method getInt*[T](c: Data[T], i: int): int =
  int(c.data[i])

method getGeneric*(c: Column, i: int, R: typedesc): R {.base.} =
  raise newException(AssertionError, "abstract base method called")

method getGeneric*[T](c: Data[T], i: int, R: typedesc): R =
  R(c.data[i])

let c: Column = Data[string](data: @["1", "2", "3"])
#echo c.getInt(0)
#echo c.getGeneric(0, int)

#[
Learnings:
- The existence of Data[string] means that the compiler will create an
  instantiation of getInt[T] with T = string, which causes a compilation error.
- This may also explain the "generic method not attachable to object type is deprecated"
  issue: When there is an additional generic parameter (or typedesc) the compiler
  does not know which instantiations are required for getGeneric. Thus, it will
  only create the base method itself. That's why at runtime the example will
  raise the "abstract base method called" assertion error.
]#