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
  raise newException(AssertionError, "`getString` of base method should not be called.")

method getString*[T](c: Data[T], i: int): string =
  # TODO: handle mask/index
  $c.data[i]

method withIndex*(c: DataUntyped, index: Index): DataUntyped {.base.} =
  raise newException(AssertionError, "`withIndex` of base method should not be called.")

method withIndex*[T](c: Data[T], index: Index): DataUntyped {.base.} =
  Data[T](
    typeInfo: c.typeInfo,
    data: c.data,
    size: c.size,
    index: index,
  )


# forwarded proc for Column -- TODO move somewhere else?

proc len*(c: Column): int {.inline.} = c.data.len

proc typeName*(c: Column): string {.inline.} = c.data.typeName

proc getString*(c: Column, i: int): string {.inline.} = c.data.getString(i)

proc `$`*(c: Column): string = $c.data
