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
import p_index
import p_utils

# -----------------------------------------------------------------------------
# Conversion
# -----------------------------------------------------------------------------

proc toSequence*(c: DataUntyped, T: typedesc): seq[T] =
  ## https://github.com/nim-lang/Nim/issues/7322
  c.assertType(T).toSequence()

proc toSequence*(c: Column, T: typedesc): seq[T] =
  ## https://github.com/nim-lang/Nim/issues/7322
  c.data.assertType(T).toSequence()

# temporarily deactivated to speed up compilation
# maybe move into separate extension module
# proc toTensor*(c: Column, T: typedesc): Tensor[T] =
#   c.assertType(T).toTensor()


# -----------------------------------------------------------------------------
# Type casts
# -----------------------------------------------------------------------------

template assertType*(c: DataUntyped, T: typedesc): Data[T] =
  if not (c of Data[T]):
    let pos = instantiationInfo()
    let msg = "Expected column of type [$1], got [$2] at $3:$4" % [
      name(T),
      c.typeName(),
      pos.filename,
      $pos.line,
    ]
    raise newException(ValueError, msg)
  cast[Data[T]](c)

template assertTypeUnsafe*(c: DataUntyped, T: typedesc): Data[T] =
  cast[Data[T]](c)


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
  result = c.data.assertType(T).data[i]


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

      proc instSymbol*(colUntyped: DataUntyped): resultType {.gensym.} =
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
      let ti = c.data.typeInfo
      # instead of using the cast we could store the real function
      # signatures in the table.
      let fPointer = tableSymbol[ti]
      let x = c.data
      let f = cast[proc (cOther: DataUntyped): resultType {.nimcall.}](fPointer)
      # FIXME, this seems to be a Nim bug, accessing c.data behind the cast isn't possible, haha
      # f(c.data)
      f(c.data)

  result += getAst(defineMethod(
    methodName, resultType, tableSymbol
  ))
  echo result.repr

implementUnary(abs, Column): col.abs().toColumn
implementUnary(sin, Column): col.sin().toColumn
implementUnary(cos, Column): col.cos().toColumn
implementUnary(tan, Column): col.tan().toColumn

forEachType(T in SomeNumber):
  registerInstantiationAbs(T)
  registerInstantiationSin(T)
  registerInstantiationCos(T)
  registerInstantiationTan(T)

# -----------------------------------------------------------------------------
# Aggregations
# -----------------------------------------------------------------------------

var registeredSumProcs = initTable[pointer, DataUntyped -> float]()

template registerSingleColumnType*(T: typedesc) =
  let ti = getTypeInfo(T)
  echo "registering single column ops for typeInfo: ", ti

  proc sum_impl*(c: DataUntyped): float {.gensym.} =
    let cTyped = c.assertType(T)
    cTyped.sum()

  registeredSumProcs[ti] = sum_impl

proc sum*(c: Column): float =
  let ti = c.data.typeInfo
  let f = registeredSumProcs[ti]
  f(c.data)


var registeredMaxProcs = initTable[(pointer, pointer), pointer]()

template registerColumnPairType*(T: typedesc, R: typedesc) =
  # Uses the trick from: https://forum.nim-lang.org/t/3267
  let tiCol = getTypeInfo(T)
  let tiRes = getTypeInfo(R)
  echo "registering column pair ops for typeInfo: T = ", tiCol, " R = ", tiRes

  proc max_impl(c: DataUntyped): R {.gensym.} =
    type RR = R
    let cTyped = c.assertType(T)
    RR(cTyped.max())

  registeredMaxProcs[(tiCol, tiRes)] = cast[pointer](max_impl)

proc max*(c: Column, R: typedesc): R =
  let tiCol = c.data.typeInfo
  let tiRes = getTypeInfo(R)
  let fPointer = registeredMaxProcs[(tiCol, tiRes)]
  let f = cast[proc (c: Column): R {.nimcall.}](fPointer)
  f(c)

# -----------------------------------------------------------------------------
# Comparison
# -----------------------------------------------------------------------------

proc `==`*[T](c: Column, scalar: T): Data[bool] =
  result = newData[bool](c.len)
  let cTyped = c.data.assertType(T)
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
# Assignment
# -----------------------------------------------------------------------------

var registeredAssignmentProcs = initTable[(pointer, pointer), pointer]()

template registerAssignmentInstantiation*(C: typedesc, T: typedesc) =
  # Uses the trick from: https://forum.nim-lang.org/t/3267
  let tiCol = getTypeInfo(C)
  let tiAss = getTypeInfo(T)
  echo "registering column pair ops for typeInfo: C = ", tiCol, " T = ", tiAss

  proc assignmentImpl(c: var Column, x: T) {.gensym.} =
    when not compiles(C(x)):
      static:
        error "Cannot convert " & $T & " to " & $C
    var cTyped = c.data.assertType(C)
    for el in cTyped.mitems:
      el = C(x)

  registeredAssignmentProcs[(tiCol, tiAss)] = cast[pointer](assignmentImpl)

proc `<-`*[T](c: var Column, scalar: T) =
  let tiCol = c.data.typeInfo
  let tiAss = getTypeInfo(T)
  let fPointer = registeredAssignmentProcs[(tiCol, tiAss)]
  let f = cast[proc (cOther: var Column, xOther: T) {.nimcall.}](fPointer)
  f(c, scalar)

registerAssignmentInstantiation(int, int)
registerAssignmentInstantiation(float, int)
registerAssignmentInstantiation(int, float)
#registerAssignmentInstantiation(int, string)

#forEachType(T in SomeFloat):
  #forEachType(T in SomeNumber):
    #registerAssignmentInstantiation(T, T)
    #registerSingleColumnType(T)
    #t(T, T)

  

# -----------------------------------------------------------------------------
# Derived procs
# -----------------------------------------------------------------------------

proc mean*(c: Column): float =
  c.sum() / c.len


# -----------------------------------------------------------------------------
# Indexing
# -----------------------------------------------------------------------------

template underlyingType[T](x: T): typedesc =
  type(items(x))

#[
proc `[]`*[T](c: Column, indexExpr: T): Column =
  # the evaluation isn't short circuiting apparently. This means that
  # the condition is a compile time error when e.g. T is a Column,
  # which does not support the underlyingType template due to a
  # missing items iterator.
  when T is seq|array and underlyingType(indexExpr) is bool:
    let index = BoolIndex(mask: @indexExpr)
    let fusedIndex = fuseIndex(c.index, index)
    Column(
      data: c.data.withIndex(fusedIndex),
      index: fusedIndex,
    )
  else:
    static:
      error "Unimplemented indexing"
]#

proc `[]`*(c: Column, indexExpr: openarray[bool]): Column =
  let index = BoolIndex(mask: @indexExpr)
  let fusedIndex = fuseIndex(c.index, index)
  Column(
    data: c.data.withIndex(fusedIndex),
    index: fusedIndex,
  )


proc `[]`*(c: Column, indexExpr: Column): Column =
  # TODO check if we either have a bool are an int-like column and dispatch
  # accordingly. Currently we only support bool masks.
  # TODO: add stack depth information to assertType so that the thrown excepction
  # uses the lineinfo for the usage on client side, not the usage here...
  let dataTyped = indexExpr.data.assertType(bool)
  let index = BoolIndex(mask: dataTyped.data)
  let fusedIndex = fuseIndex(c.index, index)
  Column(
    data: c.data.withIndex(fusedIndex),
    index: fusedIndex,
  )


template `[]`*[T](c: var Column, indexExpr: T): var Column =
  when T is seq|array and underlyingType(indexExpr) is bool:
    let index = BoolIndex(mask: @indexExpr)
    let fusedIndex = fuseIndex(c.index, index)
    #c.data = c.data.withIndex(fusedIndex)
    #c.index = fusedIndex
    #c
    var newColumn = Column(
      data: c.data.withIndex(fusedIndex),
      index: fusedIndex,
    )
    newColumn
  else:
    static:
      error "Unimplemented indexing"


#macro `[]`(c: Column, indexExpr: untyped): untyped =

