
proc getTypeInfo*(T: typedesc): pointer =
  var dummy: T
  getTypeInfo(dummy)
