type
  Index* = ref object of RootObj

  NoIndex* = ref object of Index
  BoolIndex* = ref object of Index
    mask*: seq[bool]
  IntIndex* = ref object of Index
    indices*: seq[int]


method len*(index: Index): int {.base.} =
  raise newException(AssertionError, "`len` of base method should not be called.")

method len*(index: IntIndex): int =
  index.indices.len

method len*(index: BoolIndex): int =
  result = 0
  for b in index.mask:
    if b:
      result += 1


proc `$`*(index: Index): string =
  #raise newException(AssertionError, "`len` of base method should not be called.")
  index.repr[0 ..< ^1]

#[
method `$`*(index: IntIndex): string =
  index.repr[0..^1]

method `$`*(index: BoolIndex): string =
  result = 0
  for b in index.mask:
    if b:
      result += 1
]#

proc fuseIndex*(a: Index, b: Index): Index =
  if (a of NoIndex or a.isNil) and b of BoolIndex:
    return b
  elif a of BoolIndex and b of BoolIndex:
    let aa = cast[BoolIndex](a)
    let bb = cast[BoolIndex](b)
    var res: BoolIndex = BoolIndex(mask: aa.mask)
    var i = 0
    var j = 0
    while i < res.mask.len:
      if aa.mask[i]:
        if bb.mask[j]:
          res.mask[i] = true
        else:
          res.mask[i] = false
        j += 1
      else:
        res.mask[i] = false
      i += 1
    return res
  else:
    raise newException(ValueError, "fuseIndex not implemented for given index combination")
