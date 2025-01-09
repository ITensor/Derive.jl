# TODO: Add `ndims` type parameter.
struct DefaultArrayInterface <: AbstractArrayInterface end

using TypeParameterAccessors: parenttype
function interface(a::Type{<:AbstractArray})
  parenttype(a) === a && return DefaultArrayInterface()
  return interface(parenttype(a))
end

@interface ::DefaultArrayInterface function Base.getindex(
  a::AbstractArray{<:Any,N}, I::Vararg{Int,N}
) where {N}
  return Base.getindex(a, I...)
end

@interface ::DefaultArrayInterface function Base.setindex!(
  a::AbstractArray{<:Any,N}, value, I::Vararg{Int,N}
) where {N}
  return Base.setindex!(a, value, I...)
end

@interface ::DefaultArrayInterface function Base.map!(
  f, a_dest::AbstractArray, a_srcs::AbstractArray...
)
  return Base.map!(f, a_dest, a_srcs...)
end

@interface ::DefaultArrayInterface function Base.mapreduce(
  f, op, as::AbstractArray...; kwargs...
)
  return Base.mapreduce(f, op, as...; kwargs...)
end
