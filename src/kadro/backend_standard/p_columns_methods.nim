import p_columns_datatypes
import typetraits

method `$`*(c: DataUntyped): string {.base.} =
  raise newException(AssertionError, "`$` of base method should not be called.")

method `$`*[T](c: Data[T]): string =
  let typeName = name(T)
  result = "Data[" & typeName & "](" & $c.data & ")"

method typeName*(c: DataUntyped): string {.base.} =
  raise newException(AssertionError, "`typeName` of base method should not be called.")

method typeName*[T](c: Data[T]): string =
  result = name(T)

method len*(c: DataUntyped): int {.base.} =
  raise newException(AssertionError, "`len` of base method should not be called.")

method len*[T](c: Data[T]): int =
  result = c.size

method getString*(c: DataUntyped, i: int): string {.base.} =
  raise newException(AssertionError, "`get` of base method should not be called.")

method getString*[T](c: Data[T], i: int): string =
  # TODO: handle mask/index
  $c.data[i]




proc len*(c: Column): int {.inline.} = c.data.len

proc typeName*(c: Column): string {.inline.} = c.data.typeName

proc getString*(c: Column, i: int): string {.inline.} = c.data.getString(i)

proc `$`*(c: Column): string = $c.data
