
import columns
import impltype

const impl = getImpl()
const implFeatures = getImplFeatures()

when impl == Impl.Standard:

  proc toColumn*[T](s: openarray[T]): Data[T] =
    when s is seq:
      return Data[T](data: s)
    else:
      return Data[T](data: @s)

  proc zeros*[T](length: int): Data[T] =
    let Data = Data[T](data: newSeqOfCap[T](length))
    Data.data.setLen(length)
    when ImplFeature.OpenMP notin implFeatures:
      #for i in 0 ..< length:
      #  Data.data[i] = T(0)
      zeroMem(Data.data[0].addr, length * sizeOf(T))
    else:
      omp_parallel_countup(i, length):
        Data.data[i] = T(0)
    return Data

  proc ones*[T](length: int): Data[T] =
    let Data = Data[T](data: newSeqOfCap[T](length))
    Data.data.setLen(length)
    when ImplFeature.OpenMP notin implFeatures:
      for i in 0 ..< length:
        Data.data[i] = T(1)
    else:
      omp_parallel_countup(i, length):
        Data.data[i] = T(1)
    return Data

  proc arange*[T](length: int): Data[T] =
    let Data = Data[T](data: newSeqOfCap[T](length))
    Data.data.setLen(length)
    when ImplFeature.OpenMP notin implFeatures:
      for i in 0 ..< length:
        Data.data[i] = T(i)
    else:
      omp_parallel_countup(i, length):
        Data.data[i] = T(i)
    return Data

elif impl == Impl.Arraymancer:

  import arraymancer
  import sequtils

  proc toColumn*[T](s: seq[T]): Data[T] =
    Data[T](data: s.toTensor)

  proc zeros*[T](length: int): Data[T] =
    Data[T](data: arraymancer.zeros[T](length))

  proc ones*[T](length: int): Data[T] =
    Data[T](data: arraymancer.ones[T](length))

  proc arange*[T](length: int): Data[T] =
    # FIXME: arraymancer doesn't have a range?
    let data = arraymancer.toTensor(sequtils.toSeq(0 ..< length))
    let Data = Data[T](data: data)
    Data


when isMainModule:
  block:
    let x {.used.} = zeros[int](10)
