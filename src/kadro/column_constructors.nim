
import columns
import impltype

const impl = getImpl()
const implFeatures = getImplFeatures()

when impl == Impl.Standard:

  proc toColumn*[T](s: seq[T]): TypedCol[T] =
    return TypedCol[T](data: s)

  proc zeros*[T](length: int): TypedCol[T] =
    let typedCol = TypedCol[T](data: newSeqOfCap[T](length))
    typedCol.data.setLen(length)
    when ImplFeature.OpenMP notin implFeatures:
      for i in 0 ..< length:
        typedCol.data[i] = T(0)
    else:
      omp_parallel_countup(i, length):
        typedCol.data[i] = T(0)
    return typedCol

  proc ones*[T](length: int): TypedCol[T] =
    let typedCol = TypedCol[T](data: newSeqOfCap[T](length))
    typedCol.data.setLen(length)
    when ImplFeature.OpenMP notin implFeatures:
      for i in 0 ..< length:
        typedCol.data[i] = T(1)
    else:
      omp_parallel_countup(i, length):
        typedCol.data[i] = T(1)
    return typedCol

  proc arange*[T](length: int): TypedCol[T] =
    let typedCol = TypedCol[T](data: newSeqOfCap[T](length))
    typedCol.data.setLen(length)
    when ImplFeature.OpenMP notin implFeatures:
      for i in 0 ..< length:
        typedCol.data[i] = T(i)
    else:
      omp_parallel_countup(i, length):
        typedCol.data[i] = T(i)
    return typedCol

elif impl == Impl.Arraymancer:

  import arraymancer
  import sequtils

  proc toColumn*[T](s: seq[T]): TypedCol[T] =
    TypedCol[T](data: s.toTensor)

  proc zeros*[T](length: int): TypedCol[T] =
    TypedCol[T](data: arraymancer.zeros[T](length))

  proc ones*[T](length: int): TypedCol[T] =
    TypedCol[T](data: arraymancer.ones[T](length))
    
  proc arange*[T](length: int): TypedCol[T] =
    # FIXME: arraymancer doesn't have a range?
    let data = arraymancer.toTensor(sequtils.toSeq(0 ..< length))
    let typedCol = TypedCol[T](data: data)
    typedCol
