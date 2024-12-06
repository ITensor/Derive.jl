function symbol_replace(symbol::Symbol, replacement::Pair{Symbol,Symbol})
  return Symbol(replace(String(symbol), String(replacement[1]) => String(replacement[2])))
end
function symbol_cat(symbol1::Symbol, symbol2::Symbol)
  return Symbol(symbol1, symbol2)
end

vectype(type::Symbol) = symbol_replace(type, :Array => :Vector)
mattype(type::Symbol) = symbol_replace(type, :Array => :Matrix)
vecormattype(type::Symbol) = symbol_replace(type, :Array => :VecOrMat)
anytype(type::Symbol) = symbol_cat(:Any, type)
wrappedtype(type::Symbol) = symbol_cat(:Wrapped, type)

macro vecmat_aliases(type)
  return esc(vecmat_aliases(type))
end

function vecmat_aliases(type::Symbol)
  return quote
    const $(vectype(type)){T} = $type{T,1}
    const $(mattype(type)){T} = $type{T,2}
    const $(vecormattype(type)){T} = Union{$(vectype(type)){T},$(mattype(type)){T}}
  end
end

using Adapt: Adapt, WrappedArray

# TODO: Define for types that are hardcoded to vector or matrix,
# i.e. `Adjoint`, Transpose`, `Diagonal`, etc. Maybe call it
# `wrapped_vec_aliases` and `wrapped_mat_aliases`.
macro wrapped_aliases(type)
  return esc(wrapped_aliases(type))
end

function wrapped_aliases(type::Symbol)
  return quote
    const $(wrappedtype(type)){T,N} = $(GlobalRef(Adapt, :WrappedArray)){
      T,N,$type,$type{T,N}
    }
    const $(anytype(type)){T,N} = Union{$type{T,N},$(wrappedtype(type)){T,N}}
  end
end

macro array_aliases(type)
  return esc(array_aliases(type))
end

function array_aliases(type::Symbol)
  # TODO: I tried to implement this by using `quote` and calling
  # out to the macros but I couldn't get it to work with `GlobalRef`.
  return Expr(
    :block,
    vecmat_aliases(type).args...,
    wrapped_aliases(type).args...,
    vecmat_aliases(anytype(type)).args...,
  )
end
