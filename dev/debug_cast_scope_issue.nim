type
  Object* = object
    data*: int

template test() =
  proc methodName*(o: Object): int =
    var p: pointer
    echo "o.data still exists here: ", o.data
    let f = cast[proc (o: int): int {.nimcall.}](p)
    #echo "o.data no longer accessible after the cast: ", o.data
    echo o

test()

discard methodName(Object())