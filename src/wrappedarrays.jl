using Adapt: WrappedArray

macro wrappedtype(type)
  return esc(wrappedtype(type))
end

function wrappedtype(type::Symbol)
  wrappedtype = Symbol(:Wrapped, type)
  anytype = Symbol(:Any, type)
  return quote
    const $wrappedtype{T,N} = $WrappedArray{T,N,$type,$type{T,N}}
    const $anytype{T,N} = Union{$type{T,N},$wrappedtype{T,N}}
  end
end
