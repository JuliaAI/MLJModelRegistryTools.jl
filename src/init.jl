function __init__()
    dev = parse(Bool, Base.get(ENV, "DEVELOPING_MLJ_MODEL_REGISTRY_TOOLS", "false"))
    if !dev
        @info "If you are developing MLJModelRegistryTools.jl, be sure to set "*
            "`ENV[\"DEVELOPING_MLJ_MODEL_REGISTRY_TOOLS\"] = \"true\"`. Otherwise, "*
            "the methods from `src/remote_methods.jl` from the *registered* version "*
            "of MLJModelRegistryTools.jl get applied during update, not the dev "*
            "versions. "
    end
    global REGISTRY_PATH=Ref("")
end
