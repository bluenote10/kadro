import sequtils
import macros

import columns
import tables

type
  DataFrame* = object
    columns: OrderedTable[string, Column] # we'll probably have to make it a ref table


proc newDataFrameImpl(columns: openarray[(string, Column)]): DataFrame =
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

  # for table constructors we inject the toTypeless conversion as a convenience,
  # because otherwise Nim's first-element-determines-type is a bit inconvenient.
  if columns.kind == nnkTableConstr:
    for colExpr in columns:
      expectKind colExpr, nnkExprColonExpr
      colExpr[1] = newCall(bindSym"toTypeless", colExpr[1])

  result = newCall(bindSym"newDataFrameImpl", columns)
  echo result.repr


proc len*(df: DataFrame): int {.inline.} =
  if df.columns.len == 0:
    return 0
  else:
    for key in df.columns.keys():
      result = df.columns[key].len
      break


proc toCsv*(df: DataFrame, filename: string, sep: char = ';') =
  ## Store the data frame in a CSV
  var file = open(filename, fmWrite)
  defer: file.close()

  var j = 0
  for col in df.columns.keys.pairs:
    if j > 0:
      file.write(sep)
    file.write(col)
    j += 1
  file.write("\n")

  #[
  for j, col in df.columns.keys.pairs:
    if j > 0:
      file.write(sep)
    file.write(col)
  file.write("\n")
  ]#

  #[
  for i in 0 ..< df.len:
    for j, values in df.columns.values.pairs:
      if j > 0:
        file.write(sep)
      file.write(values.data[i])
    file.write("\n")
  ]#
