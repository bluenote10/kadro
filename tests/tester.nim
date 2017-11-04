import kadro
import unittest
import arraymancer

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

  test("zeros"):
    let c = zeros[int](10)
    
  test("ones"):
    let c = ones[int](10)

  test("arange"):
    let c = arange[int](10)


suite "iterators":

  test "items":
    let c = @[1, 2, 3].toColumn
    var expected = 1
    for x in c:
      check x == expected
      expected.inc
      
  test "enumerate":
    let c = @[1, 2, 3].toColumn
    var expected = 1
    for i, x in c.enumerate:
      check i == expected - 1
      check x == expected
      expected.inc
    

      