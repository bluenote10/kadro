import ../src/kadro

import typetraits

#[
template underlyingType[T](x: T): typedesc =
  type(items(x))

proc test[T](x: T) =
  when x is openarray:
    echo "its openarray"
  when x is seq:
    echo "its seq, underlyingType: ", underlyingType(x)
  when x is array:
    echo "its array, underlyingType: ", underlyingType(x)
  when x is openarray[bool]:
    echo "its openarray[bool]"
  when x is seq[bool]:
    echo "its seq[bool]"
  when x is array[1, bool]:
    echo "its array[1, bool]"
  when x is array[2, bool]:
    echo "its array[2, bool]"
  when x is array[3, bool]:
    echo "its array[3, bool]"
  when x is seq | array and underlyingType(x) is bool:
    echo "this works"

test([true, false])
test(@[true, false])
]#

block:
  echo "\n *** BLOCK ***"
  let a = [1, 2, 3].toColumn
  let b = a[[false, true, true]]
  let c = b[[true, false]]

  #echo a.repr
  #echo b.repr
  #echo c.repr
  echo a.debug
  echo b.debug
  echo c.debug

  echo a.len
  echo b.len
  echo c.len

  echo a.sum()
  echo b.sum()
  echo c.sum()

block:
  echo "\n *** BLOCK ***"
  var a = [1, 2, 3, 4, 5].toColumn
  echo "a = ", a.repr
  var b = a[[true, false, true, false, true]]
  echo "a = ", a.debug
  echo "b = ", b.debug
  echo a.len
  echo b.len
  # TODO: check that assignment modifies both...

block:
  echo "\n *** BLOCK ***"
  let mask = [true, false, true, false, true].toColumn
  let a = [1, 2, 3, 4, 5].toColumn
  let b = a[mask]
  echo "a = ", a.debug
  echo "b = ", b.debug
  echo a.len
  echo b.len


