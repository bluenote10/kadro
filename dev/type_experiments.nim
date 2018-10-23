import typetraits

# check if when works with compound types
proc f[T: SomeNumber](x: T) =
  when T is SomeFloat:
    echo T, " is SomeReal"
  else:
    echo T, " isn't SomeReal"

f(0.0)
f(0'f32)
f(0'f64)
f(0)
f(0.uint)
