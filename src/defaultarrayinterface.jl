# TODO: Add `ndims` type parameter.
struct DefaultArrayInterface <: AbstractArrayInterface end

using TypeParameterAccessors: parenttype
function interface(a::Type{<:AbstractArray})
  parenttype(a) === a && return DefaultArrayInterface()
  return interface(parenttype(a))
end
