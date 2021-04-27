module OptionalUnits

using Unitful
using MacroTools

export @optionalunits

"""
Can be applied to function and struct definitions that use Unitful types to add default units, when the parameters that are passed to the function do not have a unit attached.

In a function definition the type parameter e.g. Unitful.Length is appended with the default unit (e.g. x::Unitful.Length→u"mm")

In a struct definition nothing additional has to be added, the field types with Unitful.Quantity will be detected

# Examples
```julia
julia> using OptionalUnits, Unitful

julia>  @optionalunits function addOneMeter(x::Unitful.Length→u"m")
            return x+1u"m"
        end

julia>  @optionalunits function addOneMeter(x::Vector{Unitful.Length→u"m"})
            return x.+1u"m"
        end

julia> @optionalunits struct Point
            x::typeof(1.0u"m")
            y::typeof(1.0u"m")
        end

julia>  Point(1,2)
```
"""
macro optionalunits(ex)

    @assert isa(ex, Expr)

    function create_unit_check(s::Symbol, u::Unitful.Unitlike, isArray::Bool)
        if isArray
            return quote
                dims = dimension.($s)
                @assert all(dims .== [first(dims)]) "The array-like type $($s) has mixed dimensions which is not supported by @optionalunits"
                if first(dims) == NoDims
                    @warn "Used default unit $($u) for array-like type" $s
                    $s *= $u
                end
            end
        else
            return quote 
                if dimension($s) == NoDims 
                    @warn "Used default unit $($u) for" $s
                    $s *= $u
                end
            end
        end
    end

    if ex.head == :function
        unitpairs = Vector{Tuple{Symbol,Unitful.Unitlike,Expr,Bool}}()
        ex = MacroTools.postwalk(ex) do x
            if @capture(x, name_::container_{par__})

                par_new = copy(par)
                for i in range(1, stop=length(par))
                    if @capture(par[i], dimension_ → unit_)
                        @assert eval(container) <: AbstractArray "Type $(container) is not supported for the use with optional units, only implementations of the AbstractArray interface are supported"
                        if length(unitpairs) != 0 && unitpairs[end][1] == name
                            error("Found two default units in type parameters for single argument $(name)")
                        end

                        @assert typeof(eval(unit)) <: Unitful.Unitlike "Annotated unit $unit is not a Unitful.Unitlike"
                        @assert (1 * eval(unit) isa eval(dimension)) "Annotated unit $unit does not have the correct dimension $dimension"

                        par[i] = :(<:$dimension)
                        par_new[i] = :(<:Real)
                        push!(unitpairs, (name, eval(unit), dimension, true))
                    end
                end
            
                return :($name::Union{$container{$(par...)},$container{$(par_new...)}})
            end
            if @capture(x, name_::dimension_ → unit_)
                @assert typeof(eval(unit)) <: Unitful.Unitlike "Annotated unit $unit is not a Unitful.Unitlike"
                @assert (1 * eval(unit) isa eval(dimension)) "Annotated unit $unit does not have the correct dimension $dimension"

                push!(unitpairs, (name, eval(unit), dimension, false))
                return :($name::Union{$dimension,Real})
            end
        
            return x
        end

        for pairs in unitpairs
            insert!(ex.args[2].args, 1, create_unit_check(pairs[1], pairs[2], pairs[4]))
        end

        return esc(prettify(ex))

    elseif ex.head == :struct
        typename = ex.args[2]
        eval(ex) # evaluate struct in local scope, to be able to execute Base.fieldnames, there has to be a better way to get the fieldnames from the expression without evaluating
        type = eval(typename)
        fieldnames = Base.fieldnames(type)

        out = Expr(:block)
        push!(out.args, ex)

        tmp = :(function $(typename)($(fieldnames...)) end)

        for i in range(1, stop=length(fieldnames))

            fieldtype = Core.fieldtype(type, i)

            if fieldtype <: Unitful.Quantity
                push!(tmp.args[2].args, create_unit_check(fieldnames[i], unit(fieldtype), false))
            elseif fieldtype <: AbstractArray && eltype(fieldtype) <: Unitful.Quantity
                push!(tmp.args[2].args, create_unit_check(fieldnames[i], unit(eltype(fieldtype)), true))
            end

            push!(tmp.args[2].args, :($(fieldnames[i]) = Base.convert(Core.fieldtype($typename, $i), $(fieldnames[i]))))

        end
        
        push!(tmp.args[2].args, :(return $(typename)($(fieldnames...))))

        push!(out.args, tmp)
        return esc(out)
    end
end

end
