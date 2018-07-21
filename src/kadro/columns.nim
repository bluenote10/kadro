import impltype

const impl = getImpl()

when impl == Impl.Arraymancer:
  import backend_arraymancer/p_columns
elif impl == Impl.Standard:
  import backend_standard/p_columns

export p_columns

