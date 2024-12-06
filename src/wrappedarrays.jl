macro vecmat_aliases(type)
  return esc(vecmat_aliases(type))
end

function vecmat_aliases(type::Symbol)
  return quote
    const $(Symbol(type, :Vector)){T} = $(Symbol(type, :Array)){T,1}
    const $(Symbol(type, :Matrix)){T} = $(Symbol(type, :Array)){T,2}
    const $(Symbol(type, :VecOrMat)){T} = Union{
      $(Symbol(type, :Vector)){T},$(Symbol(type, :Matrix)){T}
    }
  end
end

using Adapt: Adapt, WrappedArray

macro wrapped_aliases(type)
  return esc(wrapped_aliases(type))
end

function wrapped_aliases(type::Symbol)
  return quote
    const $(Symbol(:Wrapped, type, :Array)){T,N} = $(GlobalRef(Adapt, :WrappedArray)){
      T,N,$(Symbol(type, :Array)),$(Symbol(type, :Array)){T,N}
    }
    const $(Symbol(:Any, type, :Array)){T,N} = Union{
      $(Symbol(type, :Array)){T,N},$(Symbol(:Wrapped, type, :Array)){T,N}
    }
  end
end

macro array_aliases(type)
  return esc(array_aliases(type))
end

function array_aliases(type::Symbol)
  # TODO: I tried to use `quote` here but I couldn't get it to work with `GlobalRef`.
  return Expr(
    :block,
    Expr(
      :macrocall,
      :($(GlobalRef(Derive, Symbol("@vecmat_aliases")))),
      LineNumberNode(0),
      type,
    ),
    Expr(
      :macrocall,
      :($(GlobalRef(Derive, Symbol("@wrapped_aliases")))),
      LineNumberNode(0),
      type,
    ),
    Expr(
      :macrocall,
      :($(GlobalRef(Derive, Symbol("@vecmat_aliases")))),
      LineNumberNode(0),
      Symbol(:Any, type),
    ),
  )
end
