module SparseArrayDOKs

using ArrayLayouts: ArrayLayouts
using Derive: Derive, @array_aliases, @derive, @interface, AbstractArrayInterface, interface
using LinearAlgebra: LinearAlgebra

# Define an interface.
struct SparseArrayInterface <: AbstractArrayInterface end

# Define interface functions.
@interface ::SparseArrayInterface function Base.getindex(a::AbstractArray, I::Int...)
  checkbounds(a, I...)
  !isstored(a, I...) && return getunstoredindex(a, I...)
  return getstoredindex(a, I...)
end
@interface ::SparseArrayInterface function Base.setindex!(
  a::AbstractArray, value, I::Int...
)
  checkbounds(a, I...)
  iszero(value) && return a
  if !isstored(a, I...)
    setunstoredindex!(a, value, I...)
    return a
  end
  setstoredindex!(a, value, I...)
  return a
end

# Define a type that will derive the interface.
struct SparseArrayDOK{T,N} <: AbstractArray{T,N}
  storage::Dict{CartesianIndex{N},T}
  size::NTuple{N,Int}
end
storage(a::SparseArrayDOK) = a.storage
Base.size(a::SparseArrayDOK) = a.size
function SparseArrayDOK{T}(size::Int...) where {T}
  N = length(size)
  return SparseArrayDOK{T,N}(Dict{CartesianIndex{N},T}(), size)
end
# Used in `Base.similar`.
function SparseArrayDOK{T}(::UndefInitializer, size::Tuple{Vararg{Int}}) where {T}
  return SparseArrayDOK{T}(size...)
end
function isstored(a::SparseArrayDOK, I::Int...)
  return CartesianIndex(I) in keys(storage(a))
end
function getstoredindex(a::SparseArrayDOK, I::Int...)
  return storage(a)[CartesianIndex(I)]
end
function getunstoredindex(a::SparseArrayDOK, I::Int...)
  return zero(eltype(a))
end
function setstoredindex!(a::SparseArrayDOK, value, I::Int...)
  storage(a)[CartesianIndex(I)] = value
  return a
end
function setunstoredindex!(a::SparseArrayDOK, value, I::Int...)
  storage(a)[CartesianIndex(I)] = value
  return a
end
eachstoredindex(a::SparseArrayDOK) = keys(storage(a))
storedlength(a::SparseArrayDOK) = length(eachstoredindex(a))

using LinearAlgebra: Adjoint
function isstored(a::Adjoint{<:Any,<:SparseArrayDOK}, i::Int, j::Int)
  return isstored(parent(a), j, i)
end
function getstoredindex(a::Adjoint{<:Any,<:SparseArrayDOK}, i::Int, j::Int)
  return getstoredindex(parent(a), j, i)'
end
function getunstoredindex(a::Adjoint{<:Any,<:SparseArrayDOK}, i::Int, j::Int)
  return getunstoredindex(parent(a), j, i)'
end

# Specify the interface the type adheres to.
Derive.interface(::Type{<:SparseArrayDOK}) = SparseArrayInterface()

# Define aliases like `SparseMatrixDOK`, `AnySparseArrayDOK`, etc.
@array_aliases SparseArrayDOK

struct SparseArrayStyle{N} <: Broadcast.AbstractArrayStyle{N} end
SparseArrayStyle{M}(::Val{N}) where {M,N} = SparseArrayStyle{N}()

Derive.interface(::Type{<:SparseArrayStyle}) = SparseArrayInterface()

@derive SparseArrayStyle AbstractArrayStyleOps

Derive.arraytype(::SparseArrayInterface, T::Type) = SparseArrayDOK{T}

# Interface functions.
@interface ::SparseArrayInterface function Broadcast.BroadcastStyle(type::Type)
  return SparseArrayStyle{ndims(type)}()
end

# Derive the interface for the type.
@derive AnySparseArrayDOK AbstractArrayOps

end
