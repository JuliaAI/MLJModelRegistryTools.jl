using Documenter
using MLJModelRegistryTools
using DocumenterInterLinks
using MLJModelRegistryTools.GenericRegistry

const  REPO = Remotes.GitHub("JuliaAI", "MLJModelRegistryTools.jl")

makedocs(
    modules=[MLJModelRegistryTools, GenericRegistry],
    format=Documenter.HTML(
        prettyurls = true,
        collapselevel = 1,
    ),
    pages=[
        "Home" => "index.md",
        "Registry management tools" => "registry_management_tools.md",
        "Internals" => "internals.md",
    ],
    sitename="MLJModelRegistryTools.jl",
    warnonly = [:cross_references, :missing_docs],
    repo = Remotes.GitHub("JuliaAI", "MLJModelRegistryTools.jl"),
)

deploydocs(
    devbranch="dev",
    push_preview=false,
    repo="github.com/JuliaAI/MLJModelRegistryTools.jl.git",
)
