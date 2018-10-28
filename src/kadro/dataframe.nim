import sequtils
import macros

import columns
import tables

type
  DataFrame* = object
    columns: OrderedTable[string, Column] # we'll probably have to make it a ref table


proc toColumnOptional[T](x: T): Column =
  when T is Column:
    x
  else:
    x.toColumn

proc fromTable*(columns: OrderedTable[string, Column]): DataFrame =
  let keys = toSeq(keys(columns))
  if keys.len > 0:
    let length = columns[keys[0]].len
    for k in keys:
      if columns[k].len != length:
        raise newException(ValueError, "Length of columns do not match")
  DataFrame(
    columns: columns
  )

proc fromArray*(columns: openarray[(string, Column)]): DataFrame =
  if columns.len > 0:
    # perform same length check
    let length = columns[0][1].len
    for i in 1 ..< columns.len:
      if columns[i][1].len != length:
        raise newException(ValueError, "Length of columns do not match")
  DataFrame(
    columns: columns.toOrderedTable
  )

macro newDataFrame*(columns: untyped): DataFrame =
  # for table constructors we inject the toColumn conversion as a convenience,
  # because otherwise Nim's first-element-determines-type is a bit inconvenient.
  if columns.kind == nnkTableConstr:
    for colExpr in columns:
      expectKind colExpr, nnkExprColonExpr
      colExpr[1] = newCall(bindSym"toColumnOptional", colExpr[1])

  result = newCall(bindSym"fromArray", columns)
  # echo result.repr


proc len*(df: DataFrame): int {.inline.} =
  if df.columns.len == 0:
    return 0
  else:
    for key in df.columns.keys():
      result = df.columns[key].len
      break

proc `$`*(df: DataFrame): string =
  result = "DataFrame("
  for col in df.columns.keys: # FIXME: make `df.columns.keys.pairs` work; don't require initTable
    if df.columns.len > 0:
      result &= "\n"
    result &= "  \"" & col & "\": " & $df.columns[col]
  if df.columns.len > 0:
    result &= "\n"
  result &= ")"


proc toCsv*(df: DataFrame, filename: string, sep: char = ';') =
  ## Store the data frame in a CSV
  var file = open(filename, fmWrite)
  defer: file.close()

  var j = 0
  for col in df.columns.keys: # FIXME: make `df.columns.keys.pairs` work; don't require initTable
    if j > 0:
      file.write(sep)
    file.write(col)
    j += 1
  file.write("\n")

  for i in 0 ..< df.len:
    var j = 0
    for col in df.columns.values:
      if j > 0:
        file.write(sep)
      #file.write(col.data[i])
      file.write(col.data.getString(i))
      j += 1
    file.write("\n")
