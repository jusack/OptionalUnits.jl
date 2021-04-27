using OptionalUnits
using Documenter

DocMeta.setdocmeta!(OptionalUnits, :DocTestSetup, :(using OptionalUnits); recursive=true)

makedocs(;
    modules=[OptionalUnits],
    authors="Justin Ackers <justin.ackers@imte.fraunhofer.de and contributors",
    repo="https://github.com/jusack/OptionalUnits.jl/blob/{commit}{path}#{line}",
    sitename="OptionalUnits.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://jusack.github.io/OptionalUnits.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/jusack/OptionalUnits.jl",
)
