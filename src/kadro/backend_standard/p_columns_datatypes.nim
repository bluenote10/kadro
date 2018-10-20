
type
  Column* = ref object of RootObj
    typeInfo*: pointer

  TypedCol*[T] = ref object of Column
    data*: seq[T]
