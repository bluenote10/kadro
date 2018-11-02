import typetraits
import strformat
import strutils

import p_columns_datatypes
import p_index


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

method withIndex*[T](c: Data[T], index: Index): DataUntyped =
  # we cant use result because it is of type DataUntyped and we need Data[T] for the shallow copy
  var res: Data[T] = Data[T](
    typeInfo: c.typeInfo,
    # data: c.data, # creates copy, we want shallowCopy
    size: index.len,
    index: index,
  )
  shallowCopy(res.data, c.data)
  # when shadowing result and not retruning explicitly gives a dispatcher error => bug report?
  return res


# forwarded proc for Column -- TODO move somewhere else?

proc len*(c: Column): int {.inline.} = c.data.len

proc typeName*(c: Column): string {.inline.} = c.data.typeName

proc getString*(c: Column, i: int): string {.inline.} = c.data.getString(i)

proc `$`*(c: Column): string = $c.data


# -----------------------------------------------------------------------------
# Debug utils
# -----------------------------------------------------------------------------


proc convertToId[T](p: ptr T): string =
  # using strformat here triggers a very strange bug, hard to reproduce in reduced example
  #(&"0x{cast[int](p[]):X}").toLowerAscii
  cast[int](p[]).toHex.toLowerAscii

method debugGetIdDataRaw*(d: DataUntyped): string {.base.} =
  raise newException(AssertionError, "`getDataId` of base method should not be called.")

method debugGetIdDataRaw*[T](d: Data[T]): string =
  if d.data.len == 0:
    "empty"
  else:
    let p = unsafeAddr(d.data)
    convertToId(p)


proc debugGetIdDataRaw*(c: Column): string = c.data.debugGetIdDataRaw

proc debugGetIdData*(c: Column): string =
  if c.data.isNil:
    "nil"
  else:
    let p = unsafeAddr(c.data)
    convertToId(p)

proc debugGetId*(c: Column): string =
  let p = unsafeAddr(c)
  convertToId(p)


proc debug*(c: Column): string =
  &"Column(id: {c.debugGetId}, idData: {c.debugGetIdData}, idDataRaw: {c.debugGetIdDataRaw}, index: {c.index})"