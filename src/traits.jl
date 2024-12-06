# using ArrayLayouts: ArrayLayouts
# using LinearAlgebra: LinearAlgebra

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
    Base.map(::Any, ::$type...)
    Base.map!(::Any, ::Any, ::$type...)
    Broadcast.BroadcastStyle(::Type{<:$type})
    # ArrayLayouts.MemoryLayout(::Type{<:$type})
    # LinearAlgebra.mul!(::Any, ::$type, ::$type, ::Number, ::Number)
  end
end
