import sugar
import sequtils
import strutils
import typetraits
import macros
import lenientops
import tables

import tensor/backend/openmp
# import arraymancer # for toTensor

import ../macro_utils
import p_columns_datatypes
import p_columns_constructors
import p_columns_ops_typed
import p_columns_methods
import p_utils

# -----------------------------------------------------------------------------
# Conversion
# -----------------------------------------------------------------------------

proc toSequence*(c: Column, T: typedesc): seq[T] =
  ## https://github.com/nim-lang/Nim/issues/7322
  c.assertType(T).toSequence()

# temporarily deactivated to speed up compilation
# maybe move into separate extension module
# proc toTensor*(c: Column, T: typedesc): Tensor[T] =
#   c.assertType(T).toTensor()


# -----------------------------------------------------------------------------
# Type casts
# -----------------------------------------------------------------------------

template assertType*(c: Column, T: typedesc): TypedCol[T] =
  if not (c of TypedCol[T]):
    let pos = instantiationInfo()
    let msg = "Expected column of type [$1], got [$2] at $3:$4" % [
      name(T),
      c.typeName(),
      pos.filename,
      $pos.line,
    ]
    raise newException(ValueError, msg)
  cast[TypedCol[T]](c)

template assertTypeUnsafe*(c: Column, T: typedesc): TypedCol[T] =
  cast[TypedCol[T]](c)


# -----------------------------------------------------------------------------
# Untyped getters
#
# Note that untyped getters cannot be implemented as methods with
# typedescs, because methods don't allow to use typedescs. See the
# method_based_getter.nim example.
# -----------------------------------------------------------------------------

proc get*(c: Column, i: int, T: typedesc): T =
  # TODO: This should probably be changed to a proper `[]` operator
  # once the typed column has accessors. The syntax will probably
  # be something like [<index-expression>, <typedesc>].
  result = c.assertType(T).data[i]


# -----------------------------------------------------------------------------
# Macros for implementations
# -----------------------------------------------------------------------------

proc `$`(p: pointer): string =
  # use repr, but strip the newline
  p.repr[0 ..< ^1]

proc `+=`(father, child: NimNode) =
  # convenience for appending to NimNodes
  father.add(child)

macro implementUnary(methodName: untyped, resultType: typed, op: untyped): untyped =
  let methodNameString = $methodName
  let methodNameCamel = methodNameString[0].toUpperAscii & methodNameString[1 .. ^1]

  result = newStmtList()

  # initialize the registered procs table
  template defineTable(tableSymbol) =
    var tableSymbol = initTable[pointer, pointer]()

  let tableSymbol = genSym(nskVar, "registeredProcs" & methodNameCamel)
  result += getAst(defineTable(tableSymbol))

  # add the registration/instantiation
  template defineRegisterInstantiation(
    tableSymbol, regTemplSymbol, instSymbol, resultType, op, methodNameString
  ) =
    template regTemplSymbol*(T: typedesc) =
      let ti = getTypeInfo(T)
      echo "registering ", methodNameString, " for ", name(T), " (typeInfo: ", ti, ")"

      proc instSymbol*(colUntyped: Column): resultType {.gensym.} =
        let col {.inject.} = colUntyped.assertType(T)
        op

      tableSymbol[ti] = cast[pointer](instSymbol)

  let regTemplSymbol = ident("registerInstantiation" & methodNameCamel)
  let instSymbol = ident(methodNameString & "Instantiation")
  result += getAst(defineRegisterInstantiation(
    tableSymbol, regTemplSymbol, instSymbol, resultType, op, methodNameString
  ))

  # add the actual method performing the lookup
  template defineMethod(methodName, resultType, tableSymbol) =
    proc methodName*(c: Column): resultType =
      let ti = c.typeInfo
      # instead of using the cast we could store the real function
      # signatures in the table.
      let fPointer = tableSymbol[ti]
      let f = cast[proc (c: Column): resultType {.nimcall.}](fPointer)
      f(c)

  result += getAst(defineMethod(
    methodName, resultType, tableSymbol
  ))
  echo result.repr

implementUnary(abs, Column): col.abs()
implementUnary(sin, Column): col.sin()
implementUnary(cos, Column): col.cos()
implementUnary(tan, Column): col.tan()

forEachType(T in SomeNumber):
  registerInstantiationAbs(T)
  registerInstantiationSin(T)
  registerInstantiationCos(T)
  registerInstantiationTan(T)

# -----------------------------------------------------------------------------
# Aggregations
# -----------------------------------------------------------------------------

var registeredSumProcs = initTable[pointer, Column -> float]()

template registerSingleColumnType*(T: typedesc) =
  let ti = getTypeInfo(T)
  echo "registering single column ops for typeInfo: ", ti

  proc sum_impl*(c: Column): float {.gensym.} =
    let cTyped = c.assertType(T)
    cTyped.sum()

  registeredSumProcs[ti] = sum_impl

proc sum*(c: Column): float =
  let ti = c.typeInfo
  let f = registeredSumProcs[ti]
  f(c)


var registeredMaxProcs = initTable[(pointer, pointer), pointer]()

template registerColumnPairType*(T: typedesc, R: typedesc) =
  # Uses the trick from: https://forum.nim-lang.org/t/3267
  let tiCol = getTypeInfo(T)
  let tiRes = getTypeInfo(R)
  echo "registering column pair ops for typeInfo: T = ", tiCol, " R = ", tiRes

  proc max_impl(c: Column): R {.gensym.} =
    type RR = R
    let cTyped = c.assertType(T)
    RR(cTyped.max())

  registeredMaxProcs[(tiCol, tiRes)] = cast[pointer](max_impl)

proc max*(c: Column, R: typedesc): R =
  let tiCol = c.typeInfo
  let tiRes = getTypeInfo(R)
  let fPointer = registeredMaxProcs[(tiCol, tiRes)]
  let f = cast[proc (c: Column): R {.nimcall.}](fPointer)
  f(c)

# -----------------------------------------------------------------------------
# Comparison (untyped)
# -----------------------------------------------------------------------------

proc `==`*[T](c: Column, scalar: T): TypedCol[bool] =
  result = newTypedCol[bool](c.len)
  let cTyped = c.assertType(T)
  # TODO: it would be nice if we had a `assertTypeOrConvertableTo(T)`
  for i in 0 ..< c.len:
    result.data[i] = cTyped.data[i] == scalar


when not defined(noDefaultRegistration):
  registerSingleColumnType(int)
  registerSingleColumnType(int8)
  registerSingleColumnType(float)

  registerColumnPairType(int, int)
  registerColumnPairType(int, float)


# -----------------------------------------------------------------------------
# Derived procs
# -----------------------------------------------------------------------------

proc mean*(c: Column): float =
  c.sum() / c.len
