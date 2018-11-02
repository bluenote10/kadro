type
  RefObject = ref object

  Object = object
    refObj: RefObject

proc testInt(x: int): int =
  discard

proc test(o: var Object): var Object =
  discard

discard testInt(42)

var a = Object(refObj: RefObject())
var b = test(a)