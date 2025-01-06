var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"EditURL = \"../../examples/README.jl\"","category":"page"},{"location":"#Derive.jl","page":"Home","title":"Derive.jl","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"(Image: Stable) (Image: Dev) (Image: Build Status) (Image: Coverage) (Image: Code Style: Blue) (Image: Aqua)","category":"page"},{"location":"#About","page":"Home","title":"About","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"This is a package for defining and deriving functionality for objects based around interfaces and traits, outside of the Julia type hierarchy. It is heavily inspired by Moshi.@derive, which itself is inspired by Rust's derive functionality, and the design of ArrayLayouts.jl. See also ForwardMethods.jl.","category":"page"},{"location":"","page":"Home","title":"Home","text":"The basic idea is to define implementations of a set of functions for a given interface, and types can overload, or derive, those implementations by specifying the desired interface. This provides a systematic way to define implementations of functions for objects that act in a certain way but may not share convenient abstact supertypes, such as a sparse array object and wrappers around that sparse array. Like in Moshi.jl and Rust's derive functionality, traits are simply sets of functions that can be derived for a certain type.","category":"page"},{"location":"#Installation-instructions","page":"Home","title":"Installation instructions","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"This package resides in the ITensor/ITensorRegistry local registry. In order to install, simply add that registry through your package manager. This step is only required once.","category":"page"},{"location":"","page":"Home","title":"Home","text":"julia> using Pkg: Pkg\n\njulia> Pkg.Registry.add(url=\"https://github.com/ITensor/ITensorRegistry\")","category":"page"},{"location":"","page":"Home","title":"Home","text":"or:","category":"page"},{"location":"","page":"Home","title":"Home","text":"julia> Pkg.Registry.add(url=\"git@github.com:ITensor/ITensorRegistry.git\")","category":"page"},{"location":"","page":"Home","title":"Home","text":"if you want to use SSH credentials, which can make it so you don't have to enter your Github ursername and password when registering packages.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Then, the package can be added as usual through the package manager:","category":"page"},{"location":"","page":"Home","title":"Home","text":"julia> Pkg.add(\"Derive\")","category":"page"},{"location":"#Examples","page":"Home","title":"Examples","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"using Derive: Derive, @array_aliases, @derive, @interface, interface\nusing Test: @test","category":"page"},{"location":"","page":"Home","title":"Home","text":"Define an interface.","category":"page"},{"location":"","page":"Home","title":"Home","text":"struct SparseArrayInterface end","category":"page"},{"location":"","page":"Home","title":"Home","text":"Define interface functions.","category":"page"},{"location":"","page":"Home","title":"Home","text":"@interface ::SparseArrayInterface function Base.getindex(a, I::Int...)\n  checkbounds(a, I...)\n  !isstored(a, I...) && return getunstoredindex(a, I...)\n  return getstoredindex(a, I...)\nend\n@interface ::SparseArrayInterface function Base.setindex!(a, value, I::Int...)\n  checkbounds(a, I...)\n  iszero(value) && return a\n  if !isstored(a, I...)\n    setunstoredindex!(a, value, I...)\n    return a\n  end\n  setstoredindex!(a, value, I...)\n  return a\nend","category":"page"},{"location":"","page":"Home","title":"Home","text":"Define a type that will derive the interface.","category":"page"},{"location":"","page":"Home","title":"Home","text":"struct SparseArrayDOK{T,N} <: AbstractArray{T,N}\n  storage::Dict{CartesianIndex{N},T}\n  size::NTuple{N,Int}\nend\nstorage(a::SparseArrayDOK) = a.storage\nBase.size(a::SparseArrayDOK) = a.size\nfunction SparseArrayDOK{T}(size::Int...) where {T}\n  N = length(size)\n  return SparseArrayDOK{T,N}(Dict{CartesianIndex{N},T}(), size)\nend\nfunction isstored(a::SparseArrayDOK, I::Int...)\n  return CartesianIndex(I) in keys(storage(a))\nend\nfunction getstoredindex(a::SparseArrayDOK, I::Int...)\n  return storage(a)[CartesianIndex(I)]\nend\nfunction getunstoredindex(a::SparseArrayDOK, I::Int...)\n  return zero(eltype(a))\nend\nfunction setstoredindex!(a::SparseArrayDOK, value, I::Int...)\n  storage(a)[CartesianIndex(I)] = value\n  return a\nend\nfunction setunstoredindex!(a::SparseArrayDOK, value, I::Int...)\n  storage(a)[CartesianIndex(I)] = value\n  return a\nend","category":"page"},{"location":"","page":"Home","title":"Home","text":"Specify the interface the type adheres to.","category":"page"},{"location":"","page":"Home","title":"Home","text":"Derive.interface(::Type{<:SparseArrayDOK}) = SparseArrayInterface()","category":"page"},{"location":"","page":"Home","title":"Home","text":"Define aliases like SparseMatrixDOK, AnySparseArrayDOK, etc.","category":"page"},{"location":"","page":"Home","title":"Home","text":"@array_aliases SparseArrayDOK","category":"page"},{"location":"","page":"Home","title":"Home","text":"Derive the interface for the type.","category":"page"},{"location":"","page":"Home","title":"Home","text":"@derive (T=SparseArrayDOK,) begin\n  Base.getindex(::T, ::Int...)\n  Base.setindex!(::T, ::Any, ::Int...)\nend\n\na = SparseArrayDOK{Float64}(2, 2)\na[1, 1] = 2\n@test a[1, 1] == 2\n@test a[2, 1] == 0\n@test a[1, 2] == 0\n@test a[2, 2] == 0\n\n@test a isa SparseMatrixDOK\n@test a' isa AnySparseMatrixDOK","category":"page"},{"location":"","page":"Home","title":"Home","text":"Call the sparse array interface on a dense array.","category":"page"},{"location":"","page":"Home","title":"Home","text":"isstored(a::AbstractArray, I::Int...) = true\ngetstoredindex(a::AbstractArray, I::Int...) = getindex(a, I...)\nsetstoredindex!(a::AbstractArray, value, I::Int...) = setindex!(a, value, I...)\n\na = zeros(2, 2)\n@interface SparseArrayInterface() a[1, 1] = 2\n@test @interface(SparseArrayInterface(), a[1, 1]) == 2\n@test @interface(SparseArrayInterface(), a[2, 1]) == 0\n@test @interface(SparseArrayInterface(), a[1, 2]) == 0\n@test @interface(SparseArrayInterface(), a[2, 2]) == 0","category":"page"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"This page was generated using Literate.jl.","category":"page"}]
}
