function __init__()
    dev = parse(Bool, Base.get(ENV, "DEVELOPING_MLJ_MODEL_REGISTRY_TOOLS", "false"))
    if !dev
        @info "If you are developing MLJModelRegistryTools.jl, be sure to set "*
            "`ENV[\"DEVELOPING_MLJ_MODEL_REGISTRY_TOOLS\"] = \"true\"`. Otherwise, "*
            "the methods from `src/remote_methods.jl` from the *registered* version "*
            "of MLJModelRegistryTools.jl get applied during update, not the dev "*
            "versions. "
    end
    @info "Remember, if a new model is added to the model registry, or migrated from one "*
        "package to another, then you will need to make a pull request to MLJ.jl to "*
        "update the "*
        "[model descriptors](https://github.com/JuliaAI/MLJ.jl/blob/dev/docs/"*
        "ModelDescriptors.toml) used to generate the MLJ user manual. "
    global REGISTRY_PATH=Ref("")
end
