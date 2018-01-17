import kadro
import unittest
import arraymancer

import test_dataframe

suite "conversion":

  test("seq"):
    let c = @[1, 2, 3].toColumn
    check c.toSeq == @[1, 2, 3]
    check c.toTypeless.toSeq(int) == @[1, 2, 3]

  test("tensor"):
    let c = @[1, 2, 3].toColumn
    check c.toTensor == @[1, 2, 3].toTensor
    check c.toTypeless.toTensor(int) == @[1, 2, 3].toTensor


suite "constructors":

  test("toColumn"):
    let c = @[1, 2, 3].toColumn
    check c.toSeq == @[1, 2, 3]

  test("zeros"):
    let c = zeros[int](5)
    check c.toSeq == @[0, 0, 0, 0, 0]

  test("ones"):
    let c = ones[int](5)
    check c.toSeq == @[1, 1, 1, 1, 1]

  test("arange"):
    let c = arange[int](5)
    check c.toSeq == @[0, 1, 2, 3, 4]


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


suite "aggregations":

  test("sum"):
    let c = @[1, 2, 3].toColumn
    check c.sum() == 6

  test("mean"):
    let c = @[1, 2, 3].toColumn
    check c.mean() == 2
    check c.toTypeless.mean() == 2

  test("max"):
    let c = @[2, 3, 1].toColumn
    check c.max() == 3
