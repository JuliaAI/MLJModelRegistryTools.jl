# # LOGGING

const ERR_REGISTRY_PATH = ErrorException(
    "No path to the registry has been set. Run "*
        "`setpath(path)`, where `path` is the path to the registry in your local "*
        "MLJModels.jl clone. That is, do something like "*
        "`setpath(\"~/MyPkgs/MLJModels/registry\")`. "
)

# for accessing or changing the location of the registry (initially empty):

"""
    MLJModelRegistryTools.registry_path()

*Private method.*

Return the path to the registry to which management tools such as [`update`](@ref) are to
be applied. Use [`setpath`](@ref) to change.

"""
function registry_path()
    out = REGISTRY_PATH[]
    isempty(out) && throw(ERR_REGISTRY_PATH)
    return out
end

"""
    setpath(path)

Point `MLJModelRegistryTools` to the location of the registry to be modified. Ordinarily,
this is the absolute path to the subdirectory `/src/registry` of a local clone of
MLJModels.jl.

```julia-repl
julia> pwd()
"/Users/anthony/GoogleDrive/Julia/MLJ/MLJModels.jl"

julia> setpath("~/GoogleDrive/Julia/MLJ/MLJModels.jl/src/registry")
```

"""
setpath(path) = (REGISTRY_PATH[] = expanduser(path))
