# Derive.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://ITensor.github.io/Derive.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://ITensor.github.io/Derive.jl/dev/)
[![Build Status](https://github.com/ITensor/Derive.jl/actions/workflows/Tests.yml/badge.svg?branch=main)](https://github.com/ITensor/Derive.jl/actions/workflows/Tests.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/ITensor/Derive.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/ITensor/Derive.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)
[![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

## Installation instructions

This package resides in the `ITensor/ITensorRegistry` local registry.
In order to install, simply add that registry through your package manager.
This step is only required once.
```julia
julia> using Pkg: Pkg

julia> Pkg.Registry.add(url="https://github.com/ITensor/ITensorRegistry")
```
or:
```julia
julia> Pkg.Registry.add(url="git@github.com:ITensor/ITensorRegistry.git")
```
if you want to use SSH credentials, which can make it so you don't have to enter your Github ursername and password when registering packages.

Then, the package can be added as usual through the package manager:

```julia
julia> Pkg.add("Derive")
```

## Examples

````julia
using Derive: Derive, @derive, @interface, interface
using Test: @test
````

Define an interface.

````julia
struct SparseArrayInterface end
````

Define interface functions.

````julia
@interface SparseArrayInterface() function Base.getindex(a, I::Int...)
  checkbounds(a, I...)
  !isstored(a, I...) && return getunstoredindex(a, I...)
  return getstoredindex(a, I...)
end
@interface SparseArrayInterface() function Base.setindex!(a, value, I::Int...)
  checkbounds(a, I...)
  iszero(value) && return a
  if !isstored(a, I...)
    setunstoredindex!(a, value, I...)
    return a
  end
  setstoredindex!(a, value, I...)
  return a
end
````

Define a type that will derive the interface.

````julia
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
````

Speficy the interface the type adheres to.

````julia
Derive.interface(::Type{<:SparseArrayDOK}) = SparseArrayInterface()
````

Derive the interface for the type.

````julia
@derive (T=SparseArrayDOK,) begin
  Base.getindex(::T, ::Int...)
  Base.setindex!(::T, ::Any, ::Int...)
end

a = SparseArrayDOK{Float64}(2, 2)
a[1, 1] = 2
@test a[1, 1] == 2
@test a[2, 1] == 0
@test a[1, 2] == 0
@test a[2, 2] == 0
````

Call the sparse array interface on a dense array.

````julia
isstored(a::AbstractArray, I::Int...) = true
getstoredindex(a::AbstractArray, I::Int...) = getindex(a, I...)
setstoredindex!(a::AbstractArray, value, I::Int...) = setindex!(a, value, I...)

a = zeros(2, 2)
@interface SparseArrayInterface() a[1, 1] = 2
@test @interface(SparseArrayInterface(), a[1, 1]) == 2
@test @interface(SparseArrayInterface(), a[2, 1]) == 0
@test @interface(SparseArrayInterface(), a[1, 2]) == 0
@test @interface(SparseArrayInterface(), a[2, 2]) == 0
````

---

*This page was generated using [Literate.jl](https://github.com/fredrikekre/Literate.jl).*

