type
  Number = object
    x: int

proc number(): Number = Number(x: 0)

proc add(n: var Number, x: int): var Number {.discardable.} =
  n.x += x
  n

template makeVar(init: untyped): untyped =
  # interesting, when wrapping this in a block it becomes immutable. Expected?
  #block:
  var symbol = init
  symbol


block:
  # traditional constructors are var... normal single line expressions won't compile
  # echo Number().add(10).add(20)
  # echo number().add(10).add(20)
  echo makeVar(number()).add(10).add(20)
  echo number().makeVar().add(10).add(20)

  block:
    var x = block:
      var y = 0
      y += 1
      y
    echo x

  block:
    var x = makeVar(0)
    echo x



block:
  var n: Number
  n.add(10).add(20)
  echo n


template chain(symbol: untyped, expression: untyped): Number =
  block:
    var symbol: Number
    expression
    symbol


block:
  let n = chain(n, n.add(10).add(20))
  echo n

block:
  let n = chain(n):
    n.add(10).add(20)
  echo n