import dataframe

import streams
import parsecsv


proc fromCsv*(s: Stream, sep=';'): DataFrame =
  # read header
  var parser: CsvParser
  parser.open(s, "csv-stream", separator=sep)
  parser.readHeaderRow()
  while parser.readRow():
    echo "new row: "
    for col in items(parser.headers):
      echo "##", col, ":", parser.rowEntry(col), "##"
  parser.close()


proc fromCsv*(filename: string, sep=';'): DataFrame =
  let stream = newFileStream(filename, fmRead)
  if stream == nil:
    raise newException(ValueError, "Cannot open the file: " & filename)
  fromCsv(stream)


when isMainModule:

  let df = fromCsv("/tmp/test.csv")