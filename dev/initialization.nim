import criterion

type
  Mask = seq[bool]

  ColType {.pure.} = enum
    Standard, View

  Column* = ref object of RootObj
    typeInfo*: pointer

  TypedCol*[T] = ref object of Column
    data*: seq[T]  # TODO: remove access


proc getTypeInfo*(T: typedesc): pointer {.inline.} =
  var dummy: T
  getTypeInfo(dummy)


#[
func newSeqUninit*[T](len: Natural): seq[T] {.inline.} =
  ## Creates an uninitialzed seq.
  ## Contrary to newSequnitialized in system.nim this works for any subtype T
  result = newSeqOfCap[T](len)
  result.setLen(len)
]#

proc newStandard[T](size: int): TypedCol[T] =
  TypedCol[T](typeInfo: getTypeInfo(T), data: newSeq[T](size))

proc newNoInit[T](size: int): TypedCol[T] {.noInit.} =
  TypedCol[T](typeInfo: getTypeInfo(T), data: newSeq[T](size))

proc newInline[T](size: int): TypedCol[T] {.inline.} =
  TypedCol[T](typeInfo: getTypeInfo(T), data: newSeq[T](size))

proc newUninit[T](size: int): TypedCol[T] {.inline.} =
  TypedCol[T](typeInfo: getTypeInfo(T), data: newSeqUninitialized[T](size))

when false:
  discard newStandard[int](0)
  echo newSeqUninitialized[int](1000000)

when true:

  var cfg = newDefaultConfig()

  benchmark cfg:

    let s100 = newSeq[int](100)
    let s1000 = newSeq[int](1000)
    let s10000 = newSeq[int](10000)

    #[
    proc closure100() {.measure.} =
      doAssert s100.len == 100

    proc closure1000() {.measure.} =
      doAssert s1000.len == 1000

    proc closure10000() {.measure.} =
      doAssert s10000.len == 10000
    ]#

    #[
    proc noclosure100() {.measure.} =
      let s100 = newSeq[int](100)
      doAssert s100.len == 100

    proc noclosure1000() {.measure.} =
      let s1000 = newSeq[int](1000)
      doAssert s1000.len == 1000

    proc noclosure10000() {.measure.} =
      let s10000 = newSeq[int](10000)
      doAssert s10000.len == 10000
    ]#

    proc benchNewStandard() {.measure.} =
      doAssert newStandard[int](1000).data.len == 1000

    proc benchNewNoInit() {.measure.} =
      doAssert newNoInit[int](1000).data.len == 1000

    proc benchNewInline() {.measure.} =
      doAssert newInline[int](1000).data.len == 1000

    proc benchNewUninit() {.measure.} =
      doAssert newUninit[int](1000).data.len == 1000