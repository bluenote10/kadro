# Thoughts on inplace unary ops

Should `inPlace` be a static bool argument?

This would require overloading all unary ops with a var and non-var versions,
and adding `when inPlace` branching to both, with a compile time error for the
non-var + inPlace=true case.

However, the return type remains an issue:

For the non-var overload the implementation is free to chose any return type,
allowing to go for the common denomitor type for the operation, e.g. 
`T: SomeNumber -> float` for `sin`.

(On the other hand there may be operations where `T: SomeNumber -> T`
is preferred even in the non-var case?)

For the var operation the signature could either be

1. `T: SomeNumber -> T`
2. `T: SomeNumber -> float`

(1) would have the drawback that the `inPlace=false` case has different 
return types depending on whether the column is let or var. For instance
for an int column `a` the result `a.sin()` would be a float cloumn
if `a` is a let, and an int column if `a` is a var. That's not an option.

(2) would have the drawback that it would only work in the `T is float`
case, i.e., requiring another static when check with error.

Example implementation:

    proc sin*[T: SomeNumber](c: TypedCol[T], inPlace: static[bool] = false): TypedCol[float] =
    when inPlace:
        static:
        error: "TypeCol needs to be a var for in place operation"
    else:
        result = newTypedCol[float](c.len)
        for i, x in c.data:
        result.data[i] = math.sin(x.float)

    proc sin*[T: SomeNumber](c: var TypedCol[T], inPlace: static[bool] = false): TypedCol[float] =
    when inPlace:
        # TODO: T is float check required
        for i, x in c.data:
        c.data[i] = math.sin(x.float)
        return c
    else:
        result = newTypedCol[float](c.len)
        for i, x in c.data:
        result.data[i] = math.sin(x.float)

Since `inPlace` affects both the argument modified of `c` and the return type
it makes probably more sense to go for function pairs e.g. `sin` and `sinInPlace`.