import kadro
import unittest

import math

proc newCol[T](s: openarray[T]): TypedCol[T] =
  s.toColumn


suite "conversion":

  test("seq"):
    let c = newCol([1, 2, 3])
    check c.toSequence(int) == @[1, 2, 3]

  #[
  test("tensor"):
    let c = newCol([1, 2, 3])
    check c.toTensor == @[1, 2, 3].toTensor
  ]#


suite "constructors":

  test("toColumn"):
    let c = @[1, 2, 3].toColumn
    check c.toSequence == @[1, 2, 3]

  test("zeros"):
    let c = zeros[int](5)
    check c.toSequence == @[0, 0, 0, 0, 0]

  test("ones"):
    let c = ones[int](5)
    check c.toSequence == @[1, 1, 1, 1, 1]

  test("arange"):
    let c = arange[int](5)
    check c.toSequence == @[0, 1, 2, 3, 4]


suite "general":

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


suite "iterators":

  test("items"):
    let c = newCol([1, 2, 3])
    var expected = 1
    for x in c:
      check x == expected
      expected.inc

  test("enumerate"):
    let c = newCol([1, 2, 3])
    var expected = 1
    for i, x in c.enumerate:
      check i == expected - 1
      check x == expected
      expected.inc


suite "unary operations":

  test("sin"):
    block:
      let a = @[1, 2, 3].toColumn
      let b = a.sin()
      check a.data == @[1, 2, 3]
      check b.data == @[1.float.sin, 2.float.sin, 3.float.sin]
      check(not(compiles(a.sinInPlace())))
    block:
      var a = @[1.0, 2.0, 3.0].toColumn
      let b = a.sinInPlace()
      check a.data == @[1.float.sin, 2.float.sin, 3.float.sin]
      check b.data == @[1.float.sin, 2.float.sin, 3.float.sin]
    block:
      var a = @[1.0, 2.0, 3.0].toColumn
      let b = a.sinInPlace().sinInPlace()
      check a.data == @[1.float.sin.sin, 2.float.sin.sin, 3.float.sin.sin]
      check b.data == @[1.float.sin.sin, 2.float.sin.sin, 3.float.sin.sin]
    block:
      var a = @[1.0, 2.0, 3.0].toColumn
      var b = a.sinInPlace()
      let c = b.sinInPlace()
      check a.data == @[1.float.sin.sin, 2.float.sin.sin, 3.float.sin.sin]
      check b.data == @[1.float.sin.sin, 2.float.sin.sin, 3.float.sin.sin]
      check c.data == @[1.float.sin.sin, 2.float.sin.sin, 3.float.sin.sin]
    block:
      # due to ref semantics, chaining inPlace has this gotcha,
      # maybe not returning anything is better?
      var a = @[1.0, 2.0, 3.0].toColumn
      let b = a.sinInPlace()
      check a.data == @[1.float.sin, 2.float.sin, 3.float.sin]
      check b.data == @[1.float.sin, 2.float.sin, 3.float.sin]
      a.sinInPlace()
      check a.data == @[1.float.sin.sin, 2.float.sin.sin, 3.float.sin.sin]
      check b.data == @[1.float.sin.sin, 2.float.sin.sin, 3.float.sin.sin]


suite "aggregations":

  test("sum"):
    let c = newCol([1, 2, 3])
    check c.sum() == 6.0
    check c.sum(int) == 6
 
  test("mean"):
    let c = newCol([1, 2, 3])
    check c.mean() == 2

  test("max"):
    let c = newCol([2, 3, 1])
    check c.max() == 3


suite "comparison":

  test("== (scalar)"):
    let c = newCol([1, 2, 3])
    let res = c == 2
    check res.toSequence == @[false, true, false]

  test("== (valid types)"):
    let a = newCol([1, 2, 3])
    let b = newCol([2, 2, 2])
    let res = a == b
    check res.toSequence == @[false, true, false]

  test("== (invalid types)"):
    let a = newCol([1, 2, 3])
    let b = newCol([1.0, 2.0, 3.0])
    check(not(compiles(a == b)))

