import kadro
import unittest

suite "constructors":

  test("toColumn"):
    let c = @[1, 2, 3].toColumn

  test("zeros"):
    let c = zeros[int](10)
    
  test("ones"):
    let c = ones[int](10)

  test("arange"):
    let c = arange[int](10)
