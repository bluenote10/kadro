import columns
import tables

type
  DataFrame* = object
    columns: OrderedTable[string, Column] # we'll probably have to make it a ref table


proc newDataFrame*(columns: openarray[(string, Column)]): DataFrame =
  if columns.len > 0:
    # perform same length check
    let length = columns[0][1].len
    for i in 1 ..< columns.len:
      if columns[i][1].len != length:
        raise newException(ValueError, "Length of columns do not match")
  DataFrame(
    columns: columns.toOrderedTable
  )


proc len*(df: DataFrame): int {.inline.} =
  if df.columns.len == 0:
    return 0
  else:
    for key in df.columns.keys():
      result = df.columns[key].len
      break

