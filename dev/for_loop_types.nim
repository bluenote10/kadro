import macros
import typetraits
import sequtils

proc test(T: typedesc) =
  echo name(T)

#[
iterator items(types: openarray[typedesc]): typedesc =
  yield float

for t in [int, float]:
  test(t)

# for t in int|float:
#   test(t)

# currently even this leads to a compiler crash
# let typeArray = [float, int]
]#

macro forEachTypeImpl(ident: untyped, types: typed, body: untyped): untyped =
  let typesNode = types.getType

  if typesNode[1][0].kind != nnkSym or typesNode[1][0].strVal != "or":
    error "Expected an `or` expression, but got: " & typesNode[1].treeRepr
  let subtypes = toSeq(types.getType[1])[1 .. ^1]

  template iteration(typeIdent, typeNode, body) =
    block:
      # defining the type does not have the desired effect,
      # because it creates a new type with the given name
      # instead of producing the underlying type name.
      # type typeIdent = typeNode
      var typeIdent: typedesc[typeNode]
      body

  # TODO: we may have to convert the subtypes into a set
  # to get rid of duplicates, because the type expressions
  # don't filter duplicates.
  result = newStmtList()
  for t in subtypes:
    result.add(getAst(iteration(ident, t, body)))
  echo result.repr


macro forEachType*(inExpression, body: untyped): untyped =
  if inExpression.kind != nnkInfix or inExpression[0] != ident("in"):
    error "forEachType requires an `in` expression" 

  let ident = inExpression[1]
  let types = inExpression[2]

  template resultAst(ident, types, body) =
    bind forEachTypeImpl
    block:
      type
        tmpType = types
      forEachTypeImpl(ident, tmpType, body)

  result = getAst(resultAst(ident, types, body))
  echo result.repr


forEachType(T in float|int|uint|SomeInteger|float):
  test(T)

# Wouldn't it be more natural if Nim would allow using = instead of : here?
# Or a let binding instead of var?
# After all, this is not the same as `var: T int`.
# var T: typedesc[int]
# test(T)