
import columns
import impltype

const impl = getImpl()
const implFeatures = getImplFeatures()

when impl == Impl.Standard:

  proc toColumn*[T](s: seq[T]): Column =
    return TypedCol[T](arr: s)

  proc zeros*[T](length: int): Column =
    let typedCol = TypedCol[T](arr: newSeqOfCap[T](length))
    typedCol.arr.setLen(length)
    when impl == Impl.Standard:
      for i in 0 ..< length:
        typedCol.arr[i] = T(0)
    elif impl == Impl.OpenMP:
      omp_parallel_countup(i, length):
        typedCol.arr[i] = T(0)
    return typedCol

  proc ones*[T](length: int): Column =
    let typedCol = TypedCol[T](arr: newSeqOfCap[T](length))
    typedCol.arr.setLen(length)
    when impl == Impl.Standard:
      for i in 0 ..< length:
        typedCol.arr[i] = T(1)
    elif impl == Impl.OpenMP:
      omp_parallel_countup(i, length):
        typedCol.arr[i] = T(1)
    return typedCol

  proc arange*[T](length: int): Column =
    let typedCol = TypedCol[T](arr: newSeqOfCap[T](length))
    typedCol.arr.setLen(length)
    when impl == Impl.Standard:
      for i in 0 ..< length:
        typedCol.arr[i] = T(i)
    elif impl == Impl.OpenMP:
      omp_parallel_countup(i, length):
        typedCol.arr[i] = T(i)
    return typedCol

elif impl == Impl.Arraymancer:

  proc toColumn*[T](s: seq[T]): Column =
    return TypedCol[T](arr: s)

  proc zeros*[T](length: int): Column =
    let typedCol = TypedCol[T](arr: newSeqOfCap[T](length))
    typedCol.arr.setLen(length)
    when impl == Impl.Standard:
      for i in 0 ..< length:
        typedCol.arr[i] = T(0)
    elif impl == Impl.OpenMP:
      omp_parallel_countup(i, length):
        typedCol.arr[i] = T(0)
    return typedCol

  proc ones*[T](length: int): Column =
    let typedCol = TypedCol[T](arr: newSeqOfCap[T](length))
    typedCol.arr.setLen(length)
    when impl == Impl.Standard:
      for i in 0 ..< length:
        typedCol.arr[i] = T(1)
    elif impl == Impl.OpenMP:
      omp_parallel_countup(i, length):
        typedCol.arr[i] = T(1)
    return typedCol

  proc arange*[T](length: int): Column =
    let typedCol = TypedCol[T](arr: newSeqOfCap[T](length))
    typedCol.arr.setLen(length)
    when impl == Impl.Standard:
      for i in 0 ..< length:
        typedCol.arr[i] = T(i)
    elif impl == Impl.OpenMP:
      omp_parallel_countup(i, length):
        typedCol.arr[i] = T(i)
    return typedCol
