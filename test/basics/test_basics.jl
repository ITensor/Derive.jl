using Test: @test, @testset
include("SparseArrayDOKs.jl")
using .SparseArrayDOKs: SparseArrayDOK, storedlength

elts = (Float32, Float64, Complex{Float32}, Complex{Float64})
@testset "Derive" for elt in elts
  a = SparseArrayDOK{elt}(2, 2)
  a[1, 2] = 12
  @test a isa SparseArrayDOK{elt,2}
  @test size(a) == (2, 2)
  @test a[1, 1] == 0
  @test a[1, 1, 1] == 0
  @test a[1, 2] == 12
  @test a[1, 2, 1] == 12
  @test storedlength(a) == 1

  a = SparseArrayDOK{elt}(2, 2)
  a[1, 2] = 12
  for b in (similar(a, Float32, (3, 3)), similar(a, Float32, Base.OneTo.((3, 3))))
    @test b isa SparseArrayDOK{Float32,2}
    @test b == zeros(Float32, 3, 3)
    @test size(b) == (3, 3)
  end

  a = SparseArrayDOK{elt}(2, 2)
  a[1, 2] = 12
  b = similar(a)
  bc = Broadcast.Broadcasted(x -> 2x, (a,))
  copyto!(b, bc)
  @test b isa SparseArrayDOK{elt,2}
  @test b == [0 24; 0 0]
  @test storedlength(b) == 1

  a = SparseArrayDOK{elt}(3, 3, 3)
  a[1, 2, 3] = 123
  b = permutedims(a, (2, 3, 1))
  @test b isa SparseArrayDOK{elt,3}
  @test b[2, 3, 1] == 123
  @test storedlength(b) == 1

  a = SparseArrayDOK{elt}(2, 2)
  a[1, 2] = 12
  b = copy(a')
  @test b isa SparseArrayDOK{elt,2}
  @test b == [0 0; 12 0]
  @test storedlength(b) == 1

  a = SparseArrayDOK{elt}(2, 2)
  a[1, 2] = 12
  b = map(x -> 2x, a)
  @test b isa SparseArrayDOK{elt,2}
  @test b == [0 24; 0 0]
  @test storedlength(b) == 1

  a = SparseArrayDOK{elt}(2, 2)
  a[1, 2] = 12
  b = a * a'
  @test b isa SparseArrayDOK{elt,2}
  @test b == [144 0; 0 0]
  @test storedlength(b) == 1

  a = SparseArrayDOK{elt}(2, 2)
  a[1, 2] = 12
  b = a .+ 2 .* a'
  @test b isa SparseArrayDOK{elt,2}
  @test b == [0 12; 24 0]
  @test storedlength(b) == 2

  a = SparseArrayDOK{elt}(2, 2)
  a[1, 2] = 12
  b = a[1:2, 2]
  @test b isa SparseArrayDOK{elt,1}
  @test b == [12, 0]
  @test storedlength(b) == 1
end
