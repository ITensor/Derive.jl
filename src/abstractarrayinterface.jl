# TODO: Add `ndims` type parameter.
abstract type AbstractArrayInterface <: AbstractInterface end

using ArrayLayouts: ArrayLayouts

@interface AbstractArrayInterface function Base.getindex(a, I...)
  return ArrayLayouts.layout_getindex(a, I...)
end

@interface AbstractArrayInterface function Base.getindex(a, I::Int...)
  # TODO: Maybe define as `ArrayLayouts.layout_getindex(a, I...)` or
  # `invoke(getindex, Tuple{AbstractArray,Vararg{Any}}, a, I...)`.
  # TODO: Use `MethodError`?
  return error("Not implemented.")
end

# TODO: Is this needed? Can we just use `Broadcast.AbstractArrayStyle`?
abstract type AbstractArrayStyle{N} <: Broadcast.AbstractArrayStyle{N} end

# TODO: Is this needed? Can we just use `Broadcast.DefaultArrayStyle`?
struct DefaultArrayStyle{N} <: AbstractArrayStyle{N} end

DefaultArrayStyle{M}(::Val{N}) where {M,N} = DefaultArrayStyle{N}()

@interface AbstractArrayInterface function Broadcast.BroadcastStyle(type::Type)
  return DefaultArrayStyle{ndims(type)}()
end

@interface AbstractArrayInterface function Base.similar(
  a, T::Type, size::Tuple{Vararg{Int}}
)
  # TODO: Maybe define as `Array{T}(undef, size...)` or
  # `invoke(Base.similar, Tuple{AbstractArray,Type,Vararg{Int}}, a, T, size)`.
  # TODO: Use `MethodError`?
  return error("Not implemented.")
end

# TODO: Is this a good definition?
# TODO: Turn this into an `@interface AbstractArrayInterface` function?
function Base.similar(bc::Broadcast.Broadcasted{<:AbstractArrayStyle}, T::Type, axes::Tuple)
  interface_similar = InterfaceFunction(interface(bc.style), similar)
  return interface_similar(bc, T, axes)
end

# TODO: Make this more general, handle mixtures of integers and ranges (`Union{Integer,Base.OneTo}`).
@interface AbstractArrayInterface function Base.similar(
  a, T::Type, axes::Tuple{Vararg{Base.OneTo}}
)
  # TODO: Use `Base.to_shape(axes)` or
  # `Base.invoke(similar, Tuple{AbstractArray,Type,Tuple{Union{Integer,Base.OneTo},Vararg{Union{Integer,Base.OneTo}}}}, a, T, axes)`.
  ## TODO: Try this, this requires defining `interface(::Broadcast.Broadcasted)`.
  ## interface_similar = InterfaceFunction(interface(a), similar)
  ## return interface_similar(interface, a, T, Base.to_shape(axes))
  return similar(a, T, Base.to_shape(axes))
end

using BroadcastMapConversion: map_function, map_args
# TODO: Turn this into an `@interface AbstractArrayInterface` function?
# TODO: Look into `SparseArrays.capturescalars`:
# https://github.com/JuliaSparse/SparseArrays.jl/blob/1beb0e4a4618b0399907b0000c43d9f66d34accc/src/higherorderfns.jl#L1092-L1102
function Base.copyto!(dest::AbstractArray, bc::Broadcast.Broadcasted{<:AbstractArrayStyle})
  interface_map! = InterfaceFunction(interface(bc.style), map!)
  interface_map!(map_function(bc), dest, map_args(bc)...)
  return dest
end

# This is defined in this way so we can rely on the Broadcast logic
# for determining the destination of the operation (element type, shape, etc.).
@interface AbstractArrayInterface function Base.map(f, as...)
  return f.(as...)
end

@interface AbstractArrayInterface function Base.map!(f, dest, as...)
  # TODO: Maybe define as
  # `invoke(Base.map!, Tuple{Any,AbstractArray,Vararg{AbstractArray}}, f, dest, as...)`.
  # TODO: Use `MethodError`?
  return error("Not implemented.")
end

@interface AbstractArrayInterface function Base.permutedims!(a_dest, a_src, perm)
  a_dest .= PermutedDimsArray(a_src, perm)
  return a_dest
end

using LinearAlgebra: LinearAlgebra
# This then requires overloading:
# function ArrayLayouts.materialize!(
#  m::MatMulMatAdd{<:AbstractSparseLayout,<:AbstractSparseLayout,<:AbstractSparseLayout}
# )
#   # Matmul implementation.
# end
@interface AbstractArrayInterface function LinearAlgebra.mul!(a_dest, a1, a2, α, β)
  return ArrayLayouts.mul!(a_dest, a1, a2, α, β)
end

@interface AbstractArrayInterface function ArrayLayouts.MemoryLayout(type::Type)
  # TODO: Define as `UnknownLayout()`?
  # TODO: Use `MethodError`?
  return error("Not implemented.")
end

## TODO: Define `const AbstractMatrixInterface = AbstractArrayInterface{2}`,
## requires adding `ndims` type parameter to `AbstractArrayInterface`.
## @interface AbstractMatrixInterface function Base.*(a1, a2)
##   return ArrayLayouts.mul(a1, a2)
## end
