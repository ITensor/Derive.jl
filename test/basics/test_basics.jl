using Test: @testset
include("SparseArrayDOKs.jl")
using .SparseArrayDOKs: SparseArrayDOK, storedlength

elts = (Float32, Float64, Complex{Float32}, Complex{Float64})
@testset "Derive" for elt in elts
  a = SparseArrayDOK{elt}(2, 2)
  a[1, 2] = 12
  @test a[1, 2] == 12
  @test storedlength(a) == 1

  b = a .+ 2 .* a'
  @test b isa SparseArrayDOK{elt}
  @test b == [0 12; 24 0]
  @test storedlength(b) == 2
end
