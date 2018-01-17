import kadro
import unittest


suite "DataFrame":

    test("construction"):
      let df = newDataFrame({
        "A": ones[int](3).toTypeless,
        "B": zeros[float](3),
        "C": ["a", "b", "c"].toColumn,
      })
