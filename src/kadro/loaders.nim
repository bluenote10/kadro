import dataframe
import columns
import column_constructors

import streams
import parsecsv
import strutils
import tables
import sugar

{.experimental: "notnil".}

type
  TypeInfo = object
    isInt: bool
    isFloat: bool
    maxInt: int64
    minInt: int64


proc scanTypes*(s: Stream, sep=';'): OrderedTable[string, TypeInfo] =
  # TODO: add maximum scan value / sampling

  var parser: CsvParser
  parser.open(s, "csv-stream", separator=sep)
  parser.readHeaderRow()

  # init type infos
  var typeInfos = initOrderedTable[string, TypeInfo]()
  for col in items(parser.headers):
    typeInfos[col] = TypeInfo(
      isInt: true,
      isFloat: true,
      maxInt: 0,
      minInt: 0,
    )

  while parser.readRow():
    for col in items(parser.headers):
      let value = parser.rowEntry(col)
      try:
        let intVal = parseInt(value)
        typeInfos[col].maxInt = max(typeInfos[col].maxInt, intVal)
        typeInfos[col].minInt = min(typeInfos[col].minInt, intVal)
      except ValueError:
        typeInfos[col].isInt = false
      try:
        discard parseFloat(value)
      except ValueError:
        typeInfos[col].isFloat = false

  # Note: we must not call parser.close() because this closes the stream.
  # Instead we reset the stream position.
  s.setPosition(0)
  # echo typeInfos
  return typeInfos


type
  Parser = ref object of RootObj
    addImpl: ((Parser, string) -> void) not nil
    getColumnImpl: (Parser -> Column) not nil

  IntParser = ref object of Parser
    data: seq[int64] not nil
  FloatParser = ref object of Parser
    data: seq[float] not nil
  StringParser = ref object of Parser
    data: seq[string] not nil

proc add(p: Parser, value: string) = p.addImpl(p, value)
proc getColumn(p: Parser): Column = p.getColumnImpl(p)

# ---- IntParser ----
proc addIntParser(p: Parser, value: string) =
  try:
    let intVal = parseInt(value)
    IntParser(p).data.add(intVal)
  except ValueError:
    # TODO: improve handling of missing data
    IntParser(p).data.add(low(int64))

proc getColumnIntParser(p: Parser): Column =
  toColumn(IntParser(p).data)

# ---- FloatParser ----
proc addFloatParser(p: Parser, value: string) =
  try:
    let floatVal = parseFloat(value)
    FloatParser(p).data.add(floatVal)
  except ValueError:
    FloatParser(p).data.add(NaN)

proc getColumnFloatParser(p: Parser): Column =
  toColumn(FloatParser(p).data)

# ---- StringParser ----
proc addStringParser(p: Parser, value: string) =
  StringParser(p).data.add(value)

proc getColumnStringParser(p: Parser): Column =
  toColumn(StringParser(p).data)


proc constructParsers(typeInfos: OrderedTable[string, TypeInfo]): OrderedTable[string, Parser] =
  result = initOrderedTable[string, Parser]()
  for key, typeInfo in typeInfos.pairs:
    if typeInfo.isInt:
      result[key] = IntParser(
        addImpl: addIntParser,
        getColumnImpl: getColumnIntParser,
        data: newSeq[int64](),
      )
    elif typeInfo.isFloat:
      result[key] = FloatParser(
        addImpl: addFloatParser,
        getColumnImpl: getColumnFloatParser,
        data: newSeq[float](),
      )
    else:
      result[key] = StringParser(
        addImpl: addStringParser,
        getColumnImpl: getColumnStringParser,
        data: newSeq[string](),
      )


proc fromCsv*(s: Stream, sep=';'): DataFrame =

  let typeInfos = scanTypes(s, sep)
  let parsers = constructParsers(typeInfos)

  # read header
  var parser: CsvParser
  parser.open(s, "csv-stream", separator=sep)
  parser.readHeaderRow()

  while parser.readRow():
    # echo "new row: "
    for col in items(parser.headers):
      let value = parser.rowEntry(col)
      # echo "##", col, ":", value, "##"
      parsers[col].add(value)

  parser.close()

  # extract columns from parsers
  var data = initOrderedTable[string, Column]()
  for col, parser in parsers.pairs:
    data[col] = parser.getColumn()

  result = fromTable(data)


proc fromCsv*(filename: string, sep=';'): DataFrame =
  let stream = newFileStream(filename, fmRead)
  if stream == nil:
    raise newException(ValueError, "Cannot open the file: " & filename)
  fromCsv(stream)


when isMainModule:

  import column_constructors

  let df1 = newDataFrame({
    "A": ones[int](3),
    "B": zeros[float](3),
    "C": ["a", "b", "c"].toColumn,
  })
  df1.toCsv("/tmp/test.csv")

  let df = fromCsv("/tmp/test.csv")
  echo df