import ../src/kadro

proc map(c: Column): Column =
  ["1", "2", "3"].toColumn()

proc apply1(c: var Column): var Column =
  var t = cast[TypedCol[string]](c)
  t.data = @["a", "b", "c"]
  # cannot return t because it escapes the scope
  c

proc apply2(c: var Column): Column =
  var t = cast[TypedCol[string]](c)
  t.data = @["a", "b", "c"]
  t

block:
  let c1: Column = [1, 2, 3].toColumn()
  echo c1
  echo c1.repr
 
  let c2: Column = c1.map()
  echo c2
  echo c2.repr

block:
  var c1: Column = [1, 2, 3].toColumn()
  echo c1
  echo c1.repr
 
  var c2: Column = c1.apply1()
  echo c2
  echo c2.repr

block:
  var c1: Column = [1, 2, 3].toColumn()
  echo c1
  echo c1.repr
 
  var c2: Column = c1.apply2()
  echo c2
  echo c2.repr


type
  ColWrapper = object
    col: Column

proc apply3(c: var ColWrapper): var ColWrapper =
  #var t = cast[TypedCol[string]](c.col)
  #t.data = @["a", "b", "c"]
  #c.col = t
  c.col = @["1", "2", "3"].toColumn
  c

block:
  var c1: ColWrapper = ColWrapper(col: [1, 2, 3].toColumn())
  echo c1
  echo c1.repr
 
  var c2: ColWrapper = c1.apply3()
  echo c2
  echo c2.repr