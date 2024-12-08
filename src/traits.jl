using ArrayLayouts: ArrayLayouts
using LinearAlgebra: LinearAlgebra

# TODO: Define an `AbstractMatrixOps` trait, which is where
# matrix multiplication should be defined (both `mul!` and `*`).
#=
```julia
@derive SparseArrayDOK AbstractArrayOps
@derive SparseArrayInterface SparseArrayDOK AbstractArrayOps
```
=#
function derive(::Val{:AbstractArrayOps}, type)
  return quote
    Base.getindex(::$type, ::Int...)
    Base.setindex!(::$type, ::Any, ::Int...)
    Base.similar(::$type, ::Type, ::Tuple{Vararg{Int}})
    Base.similar(::$type, ::Type, ::Tuple{Vararg{Base.OneTo}})
    Base.map(::Any, ::$type...)
    Base.map!(::Any, ::Any, ::$type...)
    Base.permutedims!(::Any, ::$type, ::Any)
    Broadcast.BroadcastStyle(::Type{<:$type})
    ArrayLayouts.MemoryLayout(::Type{<:$type})
    LinearAlgebra.mul!(::AbstractMatrix, ::$type, ::$type, ::Number, ::Number)
  end
end
