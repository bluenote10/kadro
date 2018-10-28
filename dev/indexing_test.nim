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

let a = [1, 2, 3].toColumn
let b = a[[false, true, true]]
let c = b[[true, false]]

echo a.repr
echo b.repr
echo c.repr

echo a.len
echo b.len
echo c.len

echo a.sum()
echo b.sum()
echo c.sum()

