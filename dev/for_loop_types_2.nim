import macros
import typetraits
import sequtils

template test(T: typedesc) =
  echo name(T)
  var x: T
  echo x


macro forEachTypeImpl(ident: untyped, types: typed, body: untyped): untyped =
  let typesNode = types.getType

  if typesNode[1][0].kind != nnkSym or typesNode[1][0].strVal != "or":
    error "Expected an `or` expression, but got: " & typesNode[1].treeRepr
  let subtypes = toSeq(types.getType[1])[1 .. ^1]

  template iterateTypeAst(iterateTypeSymbol, typeIdent, body) =
    # We have to use a generic instead of a typedesc argument
    # here because the typedesc argument is affected by
    # template hygiene and I can't find a way to inject it.
    # That means that the symbol e.g. T isn't really the
    # same as the one used in the body (which is not
    # obvious when looking at the macro result AST).
    # Generics don't seem to have symbol hygiene...
    proc iterateTypeSymbol[typeIdent]() =
      body

  template iteration(iterateTypeSymbol, typeNode) =
    iterateTypeSymbol[typeNode]()

  # TODO: we may have to convert the subtypes into a set
  # to get rid of duplicates, because the type expressions
  # don't filter duplicates.
  let iterateTypeSymbol = genSym(nskProc, "iterateType")

  result = newStmtList()
  result.add(getAst(iterateTypeAst(iterateTypeSymbol, ident, body)))
  for t in subtypes:
    result.add(getAst(iteration(iterateTypeSymbol, t)))
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
