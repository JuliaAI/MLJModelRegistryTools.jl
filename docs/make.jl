using Documenter
using MLJModelRegistry
using DocumenterInterLinks
using MLJModelRegistry.GenericRegistry

const  REPO = Remotes.GitHub("JuliaAI", "MLJModelRegistry.jl")

makedocs(
    modules=[MLJModelRegistry, GenericRegistry],
    format=Documenter.HTML(
        prettyurls = true,
        collapselevel = 1,
    ),
    pages=[
        "Home" => "index.md",
        "Internals" => "internals.md",
    ],
    sitename="MLJModelRegistry.jl",
    warnonly = [:cross_references, :missing_docs],
    repo = Remotes.GitHub("JuliaAI", "MLJModelRegistry.jl"),
)

deploydocs(
    devbranch="dev",
    push_preview=false,
    repo="github.com/JuliaAI/MLJModelRegistry.jl.git",
)
