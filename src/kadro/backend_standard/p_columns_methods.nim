import p_columns_datatypes
import typetraits

method `$`*(c: Column): string {.base.} =
  raise newException(AssertionError, "`$` of base method should not be called.")

method `$`*[T](c: TypedCol[T]): string =
  let typeName = name(T)
  result = "TypedCol[" & typeName & "](" & $c.data & ")"

method typeName*(c: Column): string {.base.} =
  raise newException(AssertionError, "`typeName` of base method should not be called.")

method typeName*[T](c: TypedCol[T]): string =
  result = name(T)

method len*(c: Column): int {.base.} =
  raise newException(AssertionError, "`len` of base method should not be called.")

method len*[T](c: TypedCol[T]): int =
  result = c.data.len

method getString*(c: Column, i: int): string {.base.} =
  raise newException(AssertionError, "`get` of base method should not be called.")

method getString*[T](c: TypedCol[T], i: int): string =
  $c.data[i]
