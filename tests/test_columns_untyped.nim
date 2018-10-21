import kadro
import unittest

import math


proc newCol[T](s: openarray[T]): Column =
  s.toColumn.toTypeless


suite "[untyped] conversion":

  test("seq"):
    let c = newCol([1, 2, 3])
    check c.toSequence(int) == @[1, 2, 3]

  #[
  test("tensor"):
    let c = newCol([1, 2, 3])
    check c.toTensor == @[1, 2, 3].toTensor
  ]#


suite "[untyped] general":

  test("$"):
    let c = newCol([1, 2, 3])
    check $c == "TypedCol[int](@[1, 2, 3])"

  test("typeName"):
    let c = newCol([1, 2, 3])
    check c.typeName == "int"

  test("len"):
    let c = newCol([1, 2, 3])
    check c.len == 3

  test("getString"):
    let c = newCol([1, 2, 3])
    check c.getString(0) == "1"


suite "[untyped] iterators":
  discard # TODO


suite "[untyped] unary operations":
  discard # TODO


suite "[untyped] aggregations":

  test("sum"):
    let c = newCol([1, 2, 3])
    check c.sum() == 6.0
    # check c.sum(int) == 6 # TODO

  test("mean"):
    let c = newCol([1, 2, 3])
    check c.mean() == 2

  test("max"):
    let c = newCol([2, 3, 1])
    check c.max(int) == 3
    check c.max(float) == 3.0


suite "[untyped] comparison":

  test("== (scalar)"):
    let c = newCol([1, 2, 3])
    let res = c == 2 # TODO: can we not make it fail with e.g. int8?
    check res.toSequence == @[false, true, false]

