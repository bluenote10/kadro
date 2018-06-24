
type
  Impl* {.pure.} = enum
    Standard, Arraymancer

  ImplFeature* {.pure.} = enum
    OpenMP, Simd

# TODO infer from 'defined'
proc getImpl*(): Impl = Impl.Arraymancer

proc getImplFeatures*(): set[ImplFeature] =
  result = {}
  when defined(openmp):
    result.incl(ImplFeature.OpenMP)
  when defined(simd):
    result.incl(ImplFeature.Simd)
