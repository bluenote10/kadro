import kadro
import unittest

suite "misc":

  test "misc usage":

    proc genDynamicCol(s: string): Column =
      case s
      of "string":
        return @["1", "2", "3"].toColumn()
      of "int":
        return @[1, 2, 3].toColumn()

    proc operateOnCol(c: Column) =
      if c of TypedCol[string]:
        let cTyped = cast[TypedCol[string]](c)
        echo "string column": cTyped.arr
      elif c of TypedCol[int]:
        let cTyped = cast[TypedCol[int]](c)
        echo "int column": cTyped.arr
      else:
        echo "can't match type"

    let c1 = genDynamicCol("string")
    let c2 = genDynamicCol("int")

    echo c1
    echo c2
    operateOnCol(c1)
    operateOnCol(c2)

    block:  # block allows to re-use variable names
      let c1 = c1.assertType(string)
      let c2 = c2.assertType(int)
      echo c1.arr
      echo c2.arr

    block:  # block allows to re-use variable names
      toTyped(c1, c1, string)
      toTyped(c2, c2, int)
      echo c1.arr
      echo c2.arr