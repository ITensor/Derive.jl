using Adapt: Adapt, WrappedArray

macro array_aliases(type)
  return esc(array_aliases(type))
end

function array_aliases(type::Symbol)
  return quote
    const $(Symbol(type, :Vector)){T} = $(Symbol(type, :Array)){T,1}
    const $(Symbol(type, :Matrix)){T} = $(Symbol(type, :Array)){T,2}
    const $(Symbol(type, :VecOrMat)){T} = Union{
      $(Symbol(type, :Vector)){T},$(Symbol(type, :Matrix)){T}
    }
    const $(Symbol(:Wrapped, type, :Array)){T,N} = $(GlobalRef(Adapt, :WrappedArray)){
      T,N,$(Symbol(type, :Array)),$(Symbol(type, :Array)){T,N}
    }
    const $(Symbol(:Any, type, :Array)){T,N} = Union{
      $(Symbol(type, :Array)){T,N},$(Symbol(:Wrapped, type, :Array)){T,N}
    }
    const $(Symbol(:Any, type, :Vector)){T} = $(Symbol(:Any, type, :Array)){T,1}
    const $(Symbol(:Any, type, :Matrix)){T} = $(Symbol(:Any, type, :Array)){T,2}
    const $(Symbol(:Any, type, :VecOrMat)){T} = Union{
      $(Symbol(:Any, type, :Vector)){T},$(Symbol(:Any, type, :Matrix)){T}
    }
  end
end
