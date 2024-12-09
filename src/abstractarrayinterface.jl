# TODO: Add `ndims` type parameter.
abstract type AbstractArrayInterface <: AbstractInterface end

function interface(::Type{<:Broadcast.AbstractArrayStyle})
  return error("Not defined.")
end

function interface(::Type{<:Broadcast.Broadcasted{<:Style}}) where {Style}
  return interface(Style)
end

# TODO: Define as `Array{T}`.
arraytype(::AbstractArrayInterface, T::Type) = error("Not implemented.")

using ArrayLayouts: ArrayLayouts

@interface ::AbstractArrayInterface function Base.getindex(a::AbstractArray, I...)
  return ArrayLayouts.layout_getindex(a, I...)
end

@interface ::AbstractArrayInterface function Base.getindex(a::AbstractArray, I::Int...)
  # TODO: Maybe define as `ArrayLayouts.layout_getindex(a, I...)` or
  # `invoke(getindex, Tuple{AbstractArray,Vararg{Any}}, a, I...)`.
  # TODO: Use `MethodError`?
  return error("Not implemented.")
end

@interface ::AbstractArrayInterface function Broadcast.BroadcastStyle(type::Type)
  return Broadcast.DefaultArrayStyle{ndims(type)}()
end

@interface ::AbstractArrayInterface function Base.similar(
  a::AbstractArray, T::Type, size::Tuple{Vararg{Int}}
)
  # TODO: Maybe define as `Array{T}(undef, size...)` or
  # `invoke(Base.similar, Tuple{AbstractArray,Type,Vararg{Int}}, a, T, size)`.
  # TODO: Use `MethodError`?
  return error("Not implemented.")
end

# TODO: Make this more general, handle mixtures of integers and ranges (`Union{Integer,Base.OneTo}`).
@interface interface::AbstractArrayInterface function Base.similar(
  a::AbstractArray, T::Type, axes::Tuple{Vararg{Base.OneTo}}
)
  # TODO: Use `Base.to_shape(axes)` or
  # `Base.invoke(similar, Tuple{AbstractArray,Type,Tuple{Union{Integer,Base.OneTo},Vararg{Union{Integer,Base.OneTo}}}}, a, T, axes)`.
  return @interface interface similar(a, T, Base.to_shape(axes))
end

@interface interface::AbstractArrayInterface function Base.similar(
  bc::Broadcast.Broadcasted, T::Type, axes::Tuple
)
  # `arraytype(::AbstractInterface)` determines the default array type associated with the interface.
  return similar(arraytype(interface, T), axes)
end

using BroadcastMapConversion: map_function, map_args
# TODO: Turn this into an `@interface AbstractArrayInterface` function?
# TODO: Look into `SparseArrays.capturescalars`:
# https://github.com/JuliaSparse/SparseArrays.jl/blob/1beb0e4a4618b0399907b0000c43d9f66d34accc/src/higherorderfns.jl#L1092-L1102
@interface interface::AbstractArrayInterface function Base.copyto!(
  dest::AbstractArray, bc::Broadcast.Broadcasted
)
  @interface interface map!(map_function(bc), dest, map_args(bc)...)
  return dest
end

# This is defined in this way so we can rely on the Broadcast logic
# for determining the destination of the operation (element type, shape, etc.).
@interface ::AbstractArrayInterface function Base.map(f, as::AbstractArray...)
  # TODO: Should this be `@interface interface ...`? That doesn't support
  # broadcasting yet.
  # Broadcasting is used here to determine the destination array but that
  # could be done manually here.
  return f.(as...)
end

@interface ::AbstractArrayInterface function Base.map!(
  f, dest::AbstractArray, as::AbstractArray...
)
  # TODO: Maybe define as
  # `invoke(Base.map!, Tuple{Any,AbstractArray,Vararg{AbstractArray}}, f, dest, as...)`.
  # TODO: Use `MethodError`?
  return error("Not implemented.")
end

@interface ::AbstractArrayInterface function Base.permutedims!(
  a_dest::AbstractArray, a_src::AbstractArray, perm
)
  # TODO: Should this be `@interface interface ...`?
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
@interface ::AbstractArrayInterface function LinearAlgebra.mul!(
  a_dest::AbstractVecOrMat, a1::AbstractVecOrMat, a2::AbstractVecOrMat, α::Number, β::Number
)
  return ArrayLayouts.mul!(a_dest, a1, a2, α, β)
end

@interface ::AbstractArrayInterface function ArrayLayouts.MemoryLayout(type::Type)
  # TODO: Define as `UnknownLayout()`?
  # TODO: Use `MethodError`?
  return error("Not implemented.")
end

## TODO: Define `const AbstractMatrixInterface = AbstractArrayInterface{2}`,
## requires adding `ndims` type parameter to `AbstractArrayInterface`.
## @interface ::AbstractMatrixInterface function Base.*(a1, a2)
##   return ArrayLayouts.mul(a1, a2)
## end
