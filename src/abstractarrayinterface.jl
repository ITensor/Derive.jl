# TODO: Add `ndims` type parameter.
abstract type AbstractArrayInterface <: AbstractInterface end

# TODO: Define as `DefaultArrayInterface()`.
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

# TODO: Maybe define as `ArrayLayouts.layout_getindex(a, I...)` or
# `invoke(getindex, Tuple{AbstractArray,Vararg{Any}}, a, I...)`.
# TODO: Use `MethodError`?
@interface ::AbstractArrayInterface function Base.getindex(
  a::AbstractArray{<:Any,N}, I::Vararg{Int,N}
) where {N}
  return error("Not implemented.")
end

@interface ::AbstractArrayInterface function Broadcast.BroadcastStyle(type::Type)
  return Broadcast.DefaultArrayStyle{ndims(type)}()
end

# TODO: Maybe define as `Array{T}(undef, size...)` or
# `invoke(Base.similar, Tuple{AbstractArray,Type,Vararg{Int}}, a, T, size)`.
# TODO: Use `MethodError`?
@interface interface::AbstractArrayInterface function Base.similar(
  a::AbstractArray, T::Type, size::Tuple{Vararg{Int}}
)
  return similar(arraytype(interface, T), size)
end

@interface ::AbstractArrayInterface function Base.copy(a::AbstractArray)
  a_dest = similar(a)
  return a_dest .= a
end

# TODO: Use `Base.to_shape(axes)` or
# `Base.invoke(similar, Tuple{AbstractArray,Type,Tuple{Union{Integer,Base.OneTo},Vararg{Union{Integer,Base.OneTo}}}}, a, T, axes)`.
# TODO: Make this more general, handle mixtures of integers and ranges (`Union{Integer,Base.OneTo}`).
@interface interface::AbstractArrayInterface function Base.similar(
  a::AbstractArray, T::Type, axes::Tuple{Base.OneTo,Vararg{Base.OneTo}}
)
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
  a_dest::AbstractArray, bc::Broadcast.Broadcasted
)
  return @interface interface map!(map_function(bc), a_dest, map_args(bc)...)
end

# This captures broadcast expressions such as `a .= 2`.
# Ideally this would be handled by `map!(f, a_dest)` but that isn't defined yet:
# https://github.com/JuliaLang/julia/issues/31677
# https://github.com/JuliaLang/julia/pull/40632
@interface interface::AbstractArrayInterface function Base.copyto!(
  a_dest::AbstractArray, bc::Broadcast.Broadcasted{Broadcast.DefaultArrayStyle{0}}
)
  isempty(map_args(bc)) || error("Bad broadcast expression.")
  return @interface interface map!(map_function(bc), a_dest, a_dest)
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

# TODO: Maybe define as
# `invoke(Base.map!, Tuple{Any,AbstractArray,Vararg{AbstractArray}}, f, dest, as...)`.
# TODO: Use `MethodError`?
@interface ::AbstractArrayInterface function Base.map!(
  f, a_dest::AbstractArray, a_srcs::AbstractArray...
)
  return error("Not implemented.")
end

@interface interface::AbstractArrayInterface function Base.fill!(a::AbstractArray, value)
  @interface interface map!(Returns(value), a, a)
end

using ArrayLayouts: zero!

# `zero!` isn't defined in `Base`, but it is defined in `ArrayLayouts`
# and is useful for sparse array logic, since it can be used to empty
# the sparse array storage.
# We use a single function definition to minimize method ambiguities.
@interface interface::AbstractArrayInterface function ArrayLayouts.zero!(a::AbstractArray)
  # More generally, the first codepath could be taking if `zero(eltype(a))`
  # is defined and the elements are immutable.
  f = eltype(a) <: Number ? Returns(zero(eltype(a))) : zero!
  return @interface interface map!(f, a, a)
end

# Specialized version of `Base.zero` written in terms of `ArrayLayouts.zero!`.
# This is friendlier for sparse arrays since `ArrayLayouts.zero!` makes it easier
# to handle the logic of dropping all elements of the sparse array when possible.
# We use a single function definition to minimize method ambiguities.
@interface interface::AbstractArrayInterface function Base.zero(a::AbstractArray)
  # More generally, the first codepath could be taking if `zero(eltype(a))`
  # is defined and the elements are immutable.
  if eltype(a) <: Number
    return @interface interface zero!(similar(a))
  end
  return @interface interface map(interface(zero), a)
end

@interface ::AbstractArrayInterface function Base.mapreduce(
  f, op, as::AbstractArray...; kwargs...
)
  return error("Not implemented.")
end

# TODO: Generalize to multiple inputs.
@interface interface::AbstractInterface function Base.reduce(f, a::AbstractArray; kwargs...)
  return @interface interface mapreduce(identity, f, a; kwargs...)
end

@interface interface::AbstractArrayInterface function Base.all(a::AbstractArray)
  return @interface interface reduce(&, a; init=true)
end

@interface interface::AbstractArrayInterface function Base.all(
  f::Function, a::AbstractArray
)
  return @interface interface mapreduce(f, &, a; init=true)
end

@interface interface::AbstractArrayInterface function Base.iszero(a::AbstractArray)
  return @interface interface all(iszero, a)
end

@interface interface::AbstractArrayInterface function Base.isreal(a::AbstractArray)
  return @interface interface all(isreal, a)
end

@interface interface::AbstractArrayInterface function Base.permutedims!(
  a_dest::AbstractArray, a_src::AbstractArray, perm
)
  return @interface interface map!(identity, a_dest, PermutedDimsArray(a_src, perm))
end

@interface interface::AbstractArrayInterface function Base.copyto!(
  a_dest::AbstractArray, a_src::AbstractArray
)
  return @interface interface map!(identity, a_dest, a_src)
end

@interface interface::AbstractArrayInterface function Base.copy!(
  a_dest::AbstractArray, a_src::AbstractArray
)
  return @interface interface map!(identity, a_dest, a_src)
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