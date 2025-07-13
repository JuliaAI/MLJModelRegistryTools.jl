# # LOGGING

const ERR_REGISTRY_PATH = ErrorException(
    "No path to the registry has been set. Run "*
        "`setpath(path)`, where `path` is the path to the registry in your local "*
        "MLJModels.jl clone. That is, do something like "*
        "`setpath(\"~/MyPkgs/MLJModels/registry\")`. "
)

# for accessing or changing the location of the registry (initially empty):
function registry_path()
    out = REGISTRY_PATH[]
    isempty(out) && throw(ERR_REGISTRY_PATH)
    return out
end
setpath(path) = (REGISTRY_PATH[] = expanduser(path))
