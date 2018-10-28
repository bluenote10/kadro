import kadro
import unittest


suite "DataFrame":

  test("construction"):
    let df1 = newDataFrame({
      "A": ones[int](3),
      "B": zeros[float](3),
      "C": ["a", "b", "c"].toColumn,
    })
    assert df1.len == 3

    # Note that without the toTypeless macro convenience we need explicit conversion
    let cols = {
      "A": ones[int](3).toColumn,
      "B": zeros[float](3).toColumn,
      "C": ["a", "b", "c"].toColumn,
    }
    let df2 = newDataFrame(cols)
    assert df2.len == 3

  test("toCsv"):
    let df1 = newDataFrame({
      "A": ones[int](3),
      "B": zeros[float](3),
      "C": ["a", "b", "c"].toColumn,
    })
    df1.toCsv("/tmp/test.csv")

