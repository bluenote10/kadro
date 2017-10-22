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