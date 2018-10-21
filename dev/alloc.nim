import criterion

when false:
  let p = alloc(100000 * sizeof(int))
  echo p.repr
  echo cast[ptr array[100000, int]](p)[]
  p.dealloc()


when true:

  var cfg = newDefaultConfig()
  benchmark cfg:

    proc benchNewSeq(n: int) {.measure: [100, 10000, 1000000].} =
      doAssert newSeq[int](n).len == n

    proc benchNewSeqUninitialized(n: int) {.measure: [100, 10000, 1000000].} =
      doAssert newSeqUninitialized[int](n).len == n

    proc benchAlloc(n: int) {.measure: [100, 10000, 1000000].} =
      let p = alloc(n * sizeof(int))
      p.dealloc()
