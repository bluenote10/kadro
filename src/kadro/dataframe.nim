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

