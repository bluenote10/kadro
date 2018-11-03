import kadro
import unittest

suite "Assignment":
  
  test "Scalar":
    var a = [1, 2, 3, 4, 5].toColumn
    var b = a
    b <- 42
    #b <- "x"
    echo a.repr
    echo b.repr

  test "Scalar (masked)":
    var a = [1, 2, 3, 4, 5].toColumn
    var b = a[[true, false, true, false, true]]
    b <- 42
    #a <- "x"
    echo a.repr
    echo b.repr