when false:
  import typetraits # only required for priting the type name

  proc high(T: typedesc[SomeReal]): T = Inf
  proc low(T: typedesc[SomeReal]): T = NegInf

  proc requiresNumericLimits[T]() =
    let minPossible = low(T)
    let maxPossible = high(T)
    echo "Min of type ", name(T), ": ", minPossible
    echo "Max of type ", name(T), ": ", maxPossible

  requiresNumericLimits[int]()
  requiresNumericLimits[int16]()
  requiresNumericLimits[uint16]()
  requiresNumericLimits[float32]()
  requiresNumericLimits[float64]()


proc `$$`[T](x: T): string = $x

proc `$$`(x: string): string = "\"" & x & "\""

#proc newEcho*(x: varargs[expr, `$$`]) {.magic: "Echo".}

import macros

macro forwardToEcho(args: varargs[typed]): untyped =
  result = newCall(bindSym"echo")
  echo args.treeRepr
  for arg in args[0][1]:
    echo arg.repr
    result.add(arg)
  echo result.repr

template newEcho(args: varargs[typed]) =
  proc `$`(s: string): string = "\"" & s & "\""
  proc `$`(s: char): string = "'" & s & "'"
  forwardToEcho(args)

newEcho "test: ", @[1, 2, 3], @["1", "2", "3"], @['1', '2', '3']