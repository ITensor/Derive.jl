module SparseArrayDOKs

isstored(a::AbstractArray, I::CartesianIndex) = isstored(a, Tuple(I)...)
getstoredindex(a::AbstractArray, I::CartesianIndex) = getstoredindex(a, Tuple(I)...)
getunstoredindex(a::AbstractArray, I::CartesianIndex) = getunstoredindex(a, Tuple(I)...)
function setstoredindex!(a::AbstractArray, value, I::CartesianIndex)
  return setstoredindex!(a, value, Tuple(I)...)
end
function setunstoredindex!(a::AbstractArray, value, I::CartesianIndex)
  return setunstoredindex!(a, value, Tuple(I)...)
end

# A view of the stored values of an array.
# Similar to: `@view a[collect(eachstoredindex(a))]`, but the issue
# with that is it returns a `SubArray` wrapping a sparse array, which
# is then interpreted as a sparse array. Also, that involves extra
# logic for determining if the indices are stored or not, but we know
# the indices are stored.
struct StoredValues{T,A<:AbstractArray{T},I} <: AbstractVector{T}
  array::A
  storedindices::I
end
StoredValues(a::AbstractArray) = StoredValues(a, collect(eachstoredindex(a)))
Base.size(a::StoredValues) = size(a.storedindices)
Base.getindex(a::StoredValues, I::Int) = getstoredindex(a.array, a.storedindices[I])
function Base.setindex!(a::StoredValues, value, I::Int)
  return setstoredindex!(a.array, value, a.storedindices[I])
end

storedvalues(a::AbstractArray) = StoredValues(a)

using ArrayLayouts: ArrayLayouts, MatMulMatAdd, MemoryLayout
using Derive: Derive, @array_aliases, @derive, @interface, AbstractArrayInterface, interface
using LinearAlgebra: LinearAlgebra

# Define an interface.
struct SparseArrayInterface <: AbstractArrayInterface end

# Define interface functions.
@interface ::SparseArrayInterface function Base.getindex(
  a::AbstractArray{<:Any,N}, I::Vararg{Int,N}
) where {N}
  checkbounds(a, I...)
  !isstored(a, I...) && return getunstoredindex(a, I...)
  return getstoredindex(a, I...)
end
@interface ::SparseArrayInterface function Base.setindex!(
  a::AbstractArray{<:Any,N}, value, I::Vararg{Int,N}
) where {N}
  checkbounds(a, I...)
  if !isstored(a, I...)
    iszero(value) && return a
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

@interface ::SparseArrayInterface function Base.mapreduce(
  f, op, a::AbstractArray; kwargs...
)
  # TODO: Need to select a better `init`.
  return mapreduce(f, op, storedvalues(a); kwargs...)
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

perm(::PermutedDimsArray{<:Any,<:Any,p}) where {p} = p
iperm(::PermutedDimsArray{<:Any,<:Any,<:Any,ip}) where {ip} = ip

# TODO: Use `Base.PermutedDimsArrays.genperm` or
# https://github.com/jipolanco/StaticPermutations.jl?
genperm(v, perm) = map(j -> v[j], perm)

function isstored(a::PermutedDimsArray, I::Int...)
  return isstored(parent(a), genperm(I, iperm(a))...)
end
function getstoredindex(a::PermutedDimsArray, I::Int...)
  return getstoredindex(parent(a), genperm(I, iperm(a))...)
end
function getunstoredindex(a::PermutedDimsArray, I::Int...)
  return getunstoredindex(parent(a), genperm(I, iperm(a))...)
end
function eachstoredindex(a::PermutedDimsArray)
  return map(collect(eachstoredindex(parent(a)))) do I
    return CartesianIndex(genperm(I, perm(a)))
  end
end

tuple_oneto(n) = ntuple(identity, n)
## This is an optimization for `storedvalues` for DOK.
## function valuesview(d::Dict, keys)
##   return @view d.vals[[Base.ht_keyindex(d, key) for key in keys]]
## end

function eachstoredparentindex(a::SubArray)
  return filter(eachstoredindex(parent(a))) do I
    return all(d -> I[d] ∈ parentindices(a)[d], 1:ndims(parent(a)))
  end
end
function storedvalues(a::SubArray)
  return @view parent(a)[collect(eachstoredparentindex(a))]
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
function setstoredindex!(a::SubArray, value, I::Int...)
  return setstoredindex!(parent(a), value, Base.reindex(parentindices(a), I)...)
end
function setunstoredindex!(a::SubArray, value, I::Int...)
  return setunstoredindex!(parent(a), value, Base.reindex(parentindices(a), I)...)
end
function eachstoredindex(a::SubArray)
  nonscalardims = filter(tuple_oneto(ndims(parent(a)))) do d
    return !(parentindices(a)[d] isa Real)
  end
  return collect((
    CartesianIndex(
      map(nonscalardims) do d
        return findfirst(==(I[d]), parentindices(a)[d])
      end,
    ) for I in eachstoredparentindex(a)
  ))
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
