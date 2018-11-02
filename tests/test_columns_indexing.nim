import kadro
import unittest

suite "Indexing":

  test "chained boolean indices":
    let a = [1, 2, 3].toColumn
    let b = a[[false, true, true]]
    let c = b[[true, false]]

    check a.debugGetIdDataRaw == b.debugGetIdDataRaw
    check b.debugGetIdDataRaw == c.debugGetIdDataRaw
    check a.len == 3
    check b.len == 2
    check c.len == 1
    check a.sum() == 6
    check b.sum() == 5
    check c.sum() == 2
    # TODO: check that assignment isn't possible...

  test "var boolean indices":
    var a = [1, 2, 3, 4, 5].toColumn
    var b = a[[true, false, true, false, true]]
    check a.debugGetIdDataRaw == b.debugGetIdDataRaw
    check a.len == 5
    check b.len == 3
    check a.sum == 15
    check b.sum == 9
    # TODO: check that assignment modifies both...

  test "column indices":
    let mask = [true, false, true, false, true].toColumn
    let a = [1, 2, 3, 4, 5].toColumn
    let b = a[mask]
    check a.debugGetIdDataRaw == b.debugGetIdDataRaw
    check a.len == 5
    check b.len == 3
    check a.sum == 15
    check b.sum == 9


