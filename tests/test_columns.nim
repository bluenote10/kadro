import kadro
import unittest

suite "conversion":

  test("seq"):
    let c = @[1, 2, 3].toColumn
    check c.toSequence == @[1, 2, 3]
    check c.toTypeless.toSequence(int) == @[1, 2, 3]

  #[
  test("tensor"):
    let c = @[1, 2, 3].toColumn
    check c.toTensor == @[1, 2, 3].toTensor
    check c.toTypeless.toTensor(int) == @[1, 2, 3].toTensor
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
    let c = @[1, 2, 3].toColumn
    check $c == "TypedCol[int](@[1, 2, 3])"
    check $(c.toTypeless) == "TypedCol[int](@[1, 2, 3])"

  test("typeName"):
    let c = @[1, 2, 3].toColumn
    check c.typeName == "int"
    check c.toTypeless.typeName == "int"

  test("len"):
    let c = @[1, 2, 3].toColumn
    check c.len == 3
    check c.toTypeless.len == 3

  test("getString"):
    let c = @[1, 2, 3].toColumn
    check c.getString(0) == "1"
    check c.toTypeless.getString(0) == "1"


suite "iterators":

  test("items"):
    let c = @[1, 2, 3].toColumn
    var expected = 1
    for x in c:
      check x == expected
      expected.inc

  test("enumerate"):
    let c = @[1, 2, 3].toColumn
    var expected = 1
    for i, x in c.enumerate:
      check i == expected - 1
      check x == expected
      expected.inc


suite "unary operations":

  test("sin"):
    let a = @[1, 2, 3].toColumn
    let b = a.sin(inPlace=true)


suite "aggregations":

  test("sum"):
    let c = @[1, 2, 3].toColumn
    check c.sum() == 6.0
    check c.toTypeless.sum() == 6
    check c.sum(int) == 6
    # check c.toTypeless.sum(int) == 6 # TODO

  test("mean"):
    let c = @[1, 2, 3].toColumn
    check c.mean() == 2
    check c.toTypeless.mean() == 2

  test("max"):
    let c = @[2, 3, 1].toColumn
    check c.max() == 3
    check c.toTypeless.max(int) == 3
    check c.toTypeless.max(float) == 3.0

suite "comparison (typed)":

  test("== (scalar)"):
    let c = @[1, 2, 3].toColumn
    let res = c == 2
    check res.toSequence == @[false, true, false]

  test("== (valid types)"):
    let a = @[1, 2, 3].toColumn
    let b = @[2, 2, 2].toColumn
    let res = a == b
    check res.toSequence == @[false, true, false]

  test("== (invalid types)"):
    let a = @[1, 2, 3].toColumn
    let b = @[1.0, 2.0, 3.0].toColumn
    check(not(compiles(a == b)))


suite "comparison (untyped)":

  test("== (scalar)"):
    let c = @[1, 2, 3].toColumn.toTypeless
    let res = c == 2 # TODO: can we not make it fail with e.g. int8?
    check res.toSequence == @[false, true, false]

