import macros
import sequtils


macro forEachTypeImpl(ident: untyped, types: typed, body: untyped): untyped =
  let typesNode = types.getType

  if typesNode[1][0].kind != nnkSym or typesNode[1][0].strVal != "or":
    error "Expected an `or` expression, but got: " & typesNode[1].treeRepr
  let subtypes = toSeq(types.getType[1])[1 .. ^1]

  template iteration(typeIdent, typeNode, body) =
    block:
      var typeIdent: typedesc[typeNode]
      body

  # TODO: we may have to convert the subtypes into a set
  # to get rid of duplicates, because the type expressions
  # don't filter duplicates.
  result = newStmtList()
  for t in subtypes:
    result.add(getAst(iteration(ident, t, body)))
  # echo result.repr


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
  # echo result.repr
