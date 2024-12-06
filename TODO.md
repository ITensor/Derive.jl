# Fix this, there is a namespace issue:
# Use `GlobalRef`, use a generalization of `globalref_derive`.
function derive(::Val{:AbstractArrayOps}, type)
  return quote
    ArrayLayouts.MemoryLayout(::Type{<:$type})
    LinearAlgebra.mul!(::Any, ::$type, ::$type, ::Number, ::Number)
  end
end

