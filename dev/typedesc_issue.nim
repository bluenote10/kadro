
when true:
  proc sum*[T, R](s: seq[T]): R =
    var sum = R(0)
    for x in s:
      sum += R(x)
    return sum

  echo sum[int, float](@[1, 2, 3])

when false:
  proc sum*[T](s: seq[T], R: typedesc): R =
    var sum: R = 0
    for x in s:
      sum += R(x)
    return sum

  echo @[1, 2, 3].sum(float)

when false:
  template dummyConvert[T, R](x: T): R = R(x)

  proc sum*[T](s: seq[T], R: typedesc): R =
    var sum: R = 0
    for x in s:
      sum += dummyConvert[T, R](x)
    return sum

  echo @[1, 2, 3].sum(float)

