```@meta
CurrentModule = OptionalUnits
```

# OptionalUnits

Having the appropiate physical units attached to your variables is a good way to protect yourself from accidental miscalculations and keeps you from wondering if that float is supposed to be in m or mm.
However when using Unitful I reached a point, where I either had to use units in all of my code (which is not something that I want to be forced to do) or I found myself writing wrapper functions that added an implicit unit to the raw number and passed it to the function using Unitful. To automate this process I created this package.

This package defines the `@optionalunits` macro that can be attached to a function or struct definition to automatically define a function or constructor that can either use a `Unitful.Quantity` of the right dimension or use a raw number with an implicit unit allowing the user of the function to choose either the error detection mechanism of Unitfuls explicit units or the simplicity of raw numbers with implicit units.

## Usage

### Functions
!!! warning 
    Currently the `@optionalunits` macro only works with the `function f(x) end` syntax, the shorthand form `f(x)=` is not yet supported!

Applied to a function definition the `@optionalunits` macro can be used like this:
```julia
@optionalunits function addOneMeter(x::Unitful.Length→u"m")
    return x+1u"m"
end
```
Behind every type parameter that is a `Unitful.Dimension` a default unit can be annotated with → (`\rightarrow[TAB]`]). The macro changes the function definition to the following:
```julia
function addOneMeter(x::Union{Unitful.Length,Real})
    if Unitful.dimension(x) == NoDims
        @warn "Used default unit m for" x
        x *= u"m"
    end
        
    return x+1u"m"
end
```
The macro also works with array-like types of uniform dimension
```julia
@optionalunits function addOneMeter(x::Vector{Unitful.Length→u"m"})
    return x.+1u"m"
end
```
the new function definition looks slightly different:
```julia
function addOneMeter(x::Union{Vector{<:Unitful.Length},Vector{<:Real}})
    dims = Unitful.dimension(x)
    @assert all(dims .== [first(dims)]) "The array-like type x has mixed dimensions which is not supported by @optionalunits"
    if first(dims) == NoDims
        @warn "Used default unit m for array-like type" x
        x *= u"m"
    end
        
    return x.+1u"m"
end
```

This definition allows the function to be called with or without units:
```julia
julia> addOneMeter(1u"m")
2 m

julia> addOneMeter(1.0u"mm")
1.001 m

julia> addOneMeter(1.0)
┌ Warning: Used default unit m for
│   x = 1.0
└ @ Main REPL[18]:3
2.0 m

julia> addOneMeter(1.0u"m/s")
ERROR: MethodError: no method matching addOneMeter(::Quantity{Float64, 𝐋  𝐓 ^-1, Unitful.FreeUnits{(m, s^-1), 𝐋  𝐓 ^-1, nothing}})
```
Of course multiple annotated and unannotated arguments, the combination of these two versions, and the use of optional arguments works.

### Structs
To use units in a struct Unitful recommends using a concrete type for every field, i.e. a `Unitful.Quantity` with a fixed datatype, dimension and unit. Therefore, no extra annotation of default units is needed to use the `@optionalunits` macro. When applied on a struct definition the macro redefines the default outer constructor (with all Any parameters) and adds the fallback to use the default units:
```julia
@optionalunits struct Point
    x::typeof(1.0u"m")
    y::typeof(1.0u"m")
end
```
The struct definition itself is not changed, but the following outer constructor is defined:
```julia
function Point(x,y)
    if dimension(x) == NoDims
        @warn "Used default unit m for " x
        x *= u"m"
    end
    x = Base.convert(Core.fieldtype(Point, 1), x)

    if dimension(y) == NoDims
        @warn "Used default unit m for " y
        y *= u"m"
    end
    y = Base.convert(Core.fieldtype(Point, 2), y)

    return Point(x,y)
end
```
The same principle applies to fields of an array-like type.

The code can be found on [GitHub](https://github.com/jusack/OptionalUnits.jl).

## Exports

```@index
```

```@autodocs
Modules = [OptionalUnits]
```
