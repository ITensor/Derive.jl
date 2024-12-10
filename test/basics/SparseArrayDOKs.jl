module SparseArrayDOKs

using ArrayLayouts: ArrayLayouts, MatMulMatAdd, MemoryLayout
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

struct SparseArrayStyle{N} <: Broadcast.AbstractArrayStyle{N} end
SparseArrayStyle{M}(::Val{N}) where {M,N} = SparseArrayStyle{N}()

Derive.interface(::Type{<:SparseArrayStyle}) = SparseArrayInterface()

@derive SparseArrayStyle AbstractArrayStyleOps

Derive.arraytype(::SparseArrayInterface, T::Type) = SparseArrayDOK{T}

# Interface functions.
@interface ::SparseArrayInterface function Broadcast.BroadcastStyle(type::Type)
  return SparseArrayStyle{ndims(type)}()
end

struct SparseLayout <: MemoryLayout end

@interface ::SparseArrayInterface function ArrayLayouts.MemoryLayout(type::Type)
  return SparseLayout()
end

@interface ::SparseArrayInterface function Base.map!(
  f, a_dest::AbstractArray, as::AbstractArray...
)
  for I in union(eachstoredindex.(as)...)
    a_dest[I] = map(f, map(a -> a[I], as)...)
  end
  return a_dest
end

# ArrayLayouts functionality.

function ArrayLayouts.sub_materialize(::SparseLayout, a::AbstractArray, axes::Tuple)
  a_dest = similar(a)
  a_dest .= a
  return a_dest
end

function ArrayLayouts.materialize!(
  m::MatMulMatAdd{<:SparseLayout,<:SparseLayout,<:SparseLayout}
)
  a_dest, a1, a2, α, β = m.C, m.A, m.B, m.α, m.β
  for I1 in eachstoredindex(a1)
    for I2 in eachstoredindex(a2)
      if I1[2] == I2[1]
        I_dest = CartesianIndex(I1[1], I2[2])
        a_dest[I_dest] = a1[I1] * a2[I2] * α + a_dest[I_dest] * β
      end
    end
  end
  return a_dest
end

# Sparse array minimal interface
using LinearAlgebra: Adjoint
function isstored(a::Adjoint, i::Int, j::Int)
  return isstored(parent(a), j, i)
end
function getstoredindex(a::Adjoint, i::Int, j::Int)
  return getstoredindex(parent(a), j, i)'
end
function getunstoredindex(a::Adjoint, i::Int, j::Int)
  return getunstoredindex(parent(a), j, i)'
end
function eachstoredindex(a::Adjoint)
  return map(CartesianIndex ∘ reverse ∘ Tuple, collect(eachstoredindex(parent(a))))
end

function isstored(a::PermutedDimsArray, I::Int...)
  return isstored(parent(a), reverse(I)...)
end
function getstoredindex(a::PermutedDimsArray, I::Int...)
  return getstoredindex(parent(a), reverse(I)...)
end
function getunstoredindex(a::PermutedDimsArray, I::Int...)
  return getunstoredindex(parent(a), reverse(I)...)
end
function eachstoredindex(a::PermutedDimsArray)
  return map(CartesianIndex ∘ reverse ∘ Tuple, collect(eachstoredindex(parent(a))))
end

function isstored(a::SubArray, I::Int...)
  return isstored(parent(a), Base.reindex(parentindices(a), I)...)
end
function getstoredindex(a::SubArray, I::Int...)
  return getstoredindex(parent(a), Base.reindex(parentindices(a), I)...)
end
function getunstoredindex(a::SubArray, I::Int...)
  return getunstoredindex(parent(a), Base.reindex(parentindices(a), I)...)
end
function eachstoredindex(a::SubArray)
  nonscalardims = filter(ntuple(identity, ndims(parent(a)))) do d
    return !(parentindices(a)[d] isa Real)
  end
  nonscalar_parentindices = map(d -> parentindices(a)[d], nonscalardims)
  subindices = filter(eachstoredindex(parent(a))) do I
    return all(d -> I[d] ∈ parentindices(a)[d], 1:ndims(parent(a)))
  end
  return map(collect(subindices)) do I
    I_nonscalar = CartesianIndex(map(d -> I[d], nonscalardims))
    return CartesianIndex(Base.reindex(nonscalar_parentindices, Tuple(I_nonscalar)))
  end
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

# Specify the interface the type adheres to.
Derive.interface(::Type{<:SparseArrayDOK}) = SparseArrayInterface()

# Define aliases like `SparseMatrixDOK`, `AnySparseArrayDOK`, etc.
@array_aliases SparseArrayDOK

# Derive the interface for the type.
@derive AnySparseArrayDOK AbstractArrayOps

end
