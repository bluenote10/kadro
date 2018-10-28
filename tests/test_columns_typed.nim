import kadro
import unittest

import sequtils
import sugar
import math

proc newCol[T](s: openarray[T]): Data[T] =
  s.toData


suite "conversion":

  test("seq"):
    let c = newCol([1, 2, 3])
    #check c.toSequence(int) == @[1, 2, 3]

  #[
  test("tensor"):
    let c = newCol([1, 2, 3])
    check c.toTensor == @[1, 2, 3].toTensor
  ]#


suite "constructors":

  test("newData"):
    let c = newData[int](100)
    check c.len == 100
    check c.toSequence.all(x => x == 0)

  test("newDataUninit"):
    let c = newDataUninit[int](10000)
    check c.len == 10000
    # not really testable
    # check c.toSequence.any(x => x != 0)

  test("toColumn"):
    check  [1, 2, 3].toData.toSequence == @[1, 2, 3]
    check @[1, 2, 3].toData.toSequence == @[1, 2, 3]

  test("copy"):
    var a = newCol([1, 2, 3])
    var b = a.copy()
    b.applyInline: x*x
    check a.toSequence == @[1, 2, 3]
    check b.toSequence == @[1, 4, 9]

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
    check $c == "Data[int](@[1, 2, 3])"

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

  test("applyInline (call count)"):
    var callCount = 0
    proc fromCall[T](c: var Data[T]): var Data[T] =
      callCount += 1
      c
    var c = newCol([1, 2, 3])
    fromCall[int](c).applyInline(x*x)
    check callCount == 1
    check c.data == @[1, 4, 9]

  test("mapInline (call count)"):
    var callCount = 0
    proc fromCall[T](): Data[T] =
      callCount += 1
      newCol([1, 2, 3])
    let c = fromCall[int]().mapInline(x*x)
    check callCount == 1
    check c.data == @[1, 4, 9]

  test("unary behavior"):
    # using sin to test general behavior
    block:  # let map vs inPlace
      let a = @[1, 2, 3].toData
      let b = a.sin()
      check a.data == @[1, 2, 3]
      check b.data == @[1.float.sin, 2.float.sin, 3.float.sin]
      check(not(compiles(a.sinInPlace())))
    block:  # var inPlace
      var a = @[1.0, 2.0, 3.0].toData
      let b = a.sinInPlace()
      check a.data == @[1.float.sin, 2.float.sin, 3.float.sin]
      check b.data == @[1.float.sin, 2.float.sin, 3.float.sin]
    block:  # var inPlace repeated
      var a = @[1.0, 2.0, 3.0].toData
      let b = a.sinInPlace().sinInPlace()
      check a.data == @[1.float.sin.sin, 2.float.sin.sin, 3.float.sin.sin]
      check b.data == @[1.float.sin.sin, 2.float.sin.sin, 3.float.sin.sin]
    block:  # var inPlace repeated multi vars
      var a = @[1.0, 2.0, 3.0].toData
      var b = a.sinInPlace()
      let c = b.sinInPlace()
      check a.data == @[1.float.sin.sin, 2.float.sin.sin, 3.float.sin.sin]
      check b.data == @[1.float.sin.sin, 2.float.sin.sin, 3.float.sin.sin]
      check c.data == @[1.float.sin.sin, 2.float.sin.sin, 3.float.sin.sin]
    block:
      # due to ref semantics, chaining inPlace has this gotcha,
      # maybe not returning anything is better?
      var a = @[1.0, 2.0, 3.0].toData
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

  #test("mean"):
  #  let c = newCol([1, 2, 3])
  #  check c.mean() == 2

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

