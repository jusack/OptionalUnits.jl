# Open Points
* Right now it is not possible to use Complex numbers without units, since the created method dispatches on `Real` instead of `Number`, this was done, because `Unitful.Quantity` is also a subtype of `Number` and therefore the method could be called with a quantity of the wrong dimension. It would be possible to add another check for each variable, but for now the numerical values are restricted to `Real`.

* During the creating of the default constructor for a struct, the complete struct definition is evaluated in the scope of the macro to extract the fieldnames. I am not sure about the consequences this might have, so there might be a better way to extract the fieldnames from the `Expr`

* Currently the `@optionalunits` macro only works with the `function f(x) end` syntax, the shorthand form `f(x)=` is not yet supported!