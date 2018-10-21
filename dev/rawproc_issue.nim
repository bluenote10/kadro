proc f(): int = 0
let fAddr = f.rawProc

#[
template registerColumnPairType*() =

  proc max_impl*(): int {.gensym.} =
    0

  let fAddr = max_impl.rawProc

registerColumnPairType()
]#