import impltype

const impl = getImpl()

when impl == Impl.Arraymancer:
  import backend_arraymancer/p_columns
elif impl == Impl.Standard:
  import backend_standard/p_columns_datatypes
  import backend_standard/p_columns_constructors
  import backend_standard/p_columns_ops_typed
  import backend_standard/p_columns_ops_untyped

export p_columns_datatypes
export p_columns_constructors
export p_columns_ops_typed
export p_columns_ops_untyped
