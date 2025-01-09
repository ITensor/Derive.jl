using ExproniconLite: JLFunction, codegen_ast, split_function, split_function_head
using MLStyle: @match

argname(i::Int) = Symbol(:arg, i)

# Remove lines from a block.
# See: https://thautwarm.github.io/MLStyle.jl/stable/syntax/pattern/#Ast-Pattern-1
# TODO: Use this type of function to replace `DerivableInterfaces.f` with `GlobalRef(DerivableInterfaces, f)`
# and also replace `T` with `SparseArrayDOK`.
function rmlines(expr)
  return @match expr begin
    e::Expr => Expr(e.head, filter(!isnothing, map(rmlines, e.args))...)
    _::LineNumberNode => nothing
    a => a
  end
end

function globalref_derive(expr)
  return @match expr begin
    :(DerivableInterfaces.$f) => :($(GlobalRef(DerivableInterfaces, :($f))))
    e::Expr => Expr(e.head, map(globalref_derive, e.args)...)
    a => a
  end
end

macro derive(expr...)
  return esc(derive_expr(expr...))
end

#==
```julia
@derive SparseArrayInterface() Base.getindex(::SparseArrayDOK, ::Int...)

@derive SparseArrayInterface() begin
  Base.getindex(::SparseArrayDOK, ::Int...)
  Base.setindex!(::SparseArrayDOK, ::Any, ::Int...)
end

@derive (T=SparseArrayDOK,) Base.getindex(::T, ::Int...)

@derive (T=SparseArrayDOK,) begin
  Base.getindex(::T, ::Int...)
  Base.setindex!(::T, ::Any, ::Int...)
end
```
==#
function derive_expr(interface_or_types::Union{Symbol,Expr}, funcs::Expr)
  return @match funcs begin
    Expr(:call, _...) => derive_func(interface_or_types, funcs)
    Expr(:block, _...) => derive_funcs(interface_or_types, funcs)
  end
end

#==
```julia
@derive SparseArrayInterface() (T=SparseArrayDOK,) Base.getindex(::T, ::Int...)

@derive SparseArrayInterface() (T=SparseArrayDOK,) begin
  Base.getindex(::T, ::Int...)
  Base.setindex!(::T, ::Any, ::Int...)
end
```
==#
function derive_expr(interface::Union{Symbol,Expr}, types::Expr, funcs::Expr)
  return @match funcs begin
    Expr(:call, _...) => derive_func(interface, types, funcs)
    Expr(:block, _...) => derive_funcs(interface, types, funcs)
  end
end

#==
```julia
@derive SparseArrayDOK AbstractArrayOps
```
==#
function derive_expr(type::Union{Symbol,Expr}, trait::Symbol)
  return derive_trait(type, trait)
end

#==
```julia
@derive SparseArrayInterface() SparseArrayDOK AbstractArrayOps
```
==#
function derive_expr(
  interface::Union{Symbol,Expr}, types::Union{Symbol,Expr}, trait::Symbol
)
  return derive_trait(interface, types, trait)
end

function derive_funcs(args...)
  interface_and_or_types = Base.front(args)
  funcs = last(args)
  Meta.isexpr(funcs, :block) || error("Expected a block.")
  funcs = rmlines(funcs)
  return Expr(
    :block, map(func -> derive_func(interface_and_or_types..., func), funcs.args)...
  )
end

#=
In:
```julia
@derive (T=SparseArrayDOK,) Base.getindex(::T, ::Int...)
@derive SparseArrayInterface() (T=SparseArrayDOK,) Base.getindex(::T, ::Int...)
```
replace `T` with `SparseArrayDOK`.
=#
function replace_typevars(types::Expr, func::Expr)
  Meta.isexpr(types, :tuple) && all(arg -> Meta.isexpr(arg, :(=)), types.args) ||
    error("Wrong types format.")
  name, args, kwargs, whereparams, rettype = split_function_head(func)
  new_args = args
  for type_expr in types.args
    typevar, type = @match type_expr begin
      :($x = $y) => (x, y)
    end
    # TODO: Handle type parameters in other positions besides the first one.
    new_args = map(args) do arg
      return @match arg begin
        :(::$Type{<:$T}) => T == typevar ? :(::$Type{<:$type}) : :(::$Type{<:$T})
        :(::$T...) => T == typevar ? :(::$type...) : :(::$T...)
        :(::$T) => T == typevar ? :(::$type) : :(::$T)
      end
    end
  end
  _, new_func = split_function(
    codegen_ast(JLFunction(; name, args=new_args, kwargs, whereparams, rettype))
  )
  return new_func
end

function derive_func(interface::Symbol, func::Expr)
  return derive_interface_func(:($(interface)()), func)
end

#=
```julia
@derive SparseArrayInterface() Base.getindex(::SparseArrayDOK, ::Int...)
@derive (T=SparseArrayDOK,) Base.getindex(::T, ::Int...)
```
=#
function derive_func(interface_or_types::Union{Symbol,Expr}, func::Expr)
  if Meta.isexpr(interface_or_types, :tuple) &&
    all(arg -> Meta.isexpr(arg, :(=)), interface_or_types.args)
    types = interface_or_types
    return derive_func_from_types(types, func)
  end
  interface = interface_or_types
  return derive_interface_func(interface, func)
end

#=
```julia
@derive (T=SparseArrayDOK,) Base.getindex(::T, ::Int...)
```
=#
function derive_func_from_types(types::Expr, func::Expr)
  new_func = replace_typevars(types, func)
  _, args = split_function_head(func)
  _, new_args = split_function_head(new_func)
  active_argnames = map(findall(args .≠ new_args)) do i
    if Meta.isexpr(args[i], :...)
      return :($(argname(i))...)
    end
    return argname(i)
  end
  interface = globalref_derive(
    :(DerivableInterfaces.combine_interfaces($(active_argnames...)))
  )
  return derive_interface_func(interface, new_func)
end

#=
```julia
@derive SparseArrayInterface() (T=SparseArrayDOK,) Base.getindex(::T, ::Int...)
```
=#
function derive_func(interface::Union{Symbol,Expr}, types::Expr, func::Expr)
  new_func = replace_typevars(types, func)
  return derive_interface_func(:($(interface)), new_func)
end

#=
Core implementation of `@derive`.
=#
function derive_interface_func(interface::Union{Symbol,Expr}, func::Expr)
  name, args, kwargs, whereparams, rettype = split_function_head(func)
  argnames = map(argname, 1:length(args))
  named_args = map(1:length(args)) do i
    argname, arg = argnames[i], args[i]
    return @match arg begin
      :(::$T) => :($argname::$T)
      :(::$T...) => :($argname::$T...)
    end
  end
  # TODO: Insert `interface` as first argument.
  body_args = map(1:length(args)) do i
    argname, arg = argnames[i], args[i]
    return @match arg begin
      :(::$T) => :($argname)
      :(::$T...) => :($argname...)
    end
  end
  # TODO: Use the `@interface` macro rather than `DerivableInterfaces.call`
  # directly, in case we want to change the implementation.
  body_args = [interface; name; body_args...]
  body_name = @match name begin
    :($M.$f) => :(DerivableInterfaces.call)
  end
  # TODO: Remove defaults from `kwargs`.
  _, body, _ = split_function(
    codegen_ast(JLFunction(; name=body_name, args=body_args, kwargs))
  )
  jlfn = JLFunction(; name, args=named_args, kwargs, whereparams, rettype, body)
  # Use `globalref_derive` to not require having `DerivableInterfaces` in the
  # namespace when `@derive` is called.
  return globalref_derive(codegen_ast(jlfn))
end

#=
```julia
@derive SparseArrayInterface() SparseArrayDOK AbstractArrayOps
```
=#
function derive_trait(
  interface::Union{Symbol,Expr}, type::Union{Symbol,Expr}, trait::Symbol
)
  funcs = Expr(:block, derive(Val(trait), type).args...)
  return derive_funcs(interface, funcs)
end

#=
```julia
@derive SparseArrayDOK AbstractArrayOps
```
=#
function derive_trait(type::Union{Symbol,Expr}, trait::Symbol)
  types = :((T=$type,))
  funcs = Expr(:block, derive(Val(trait), :T).args...)
  return derive_funcs(types, funcs)
end
