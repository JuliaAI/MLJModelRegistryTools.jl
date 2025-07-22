# # LOGGING AND ERRORS

err_missing_package(pkg, env) = ArgumentError(
    "Before calling `update` to record metadata for \"$pkg\", this package " *
        "must be added to the project at \"$env\". "*
        "Refer to MLJModelRegistration.jl documentation for details. "
)

err_invalid_packages(skip, env) = ArgumentError(
    "One or more packages from `skip=$skip` are not in the package environment at "*
    "\"$env\". "
)

const INFO_BE_PATIENT1 = "Be patient. This could take a minute or so ... "
const INFO_BE_PATIENT10 = "Be patient. This could take ten minutes or so ..."


# # HELPERS

function clean!(dic, pkg)
    for model in keys(dic)
        api_pkg = split(dic[model][":load_path"], '.') |> first
        api_pkg == pkg || (delete!(dic, model))
    end
    return dic
end

# develop MLJModelRegistryTools into the specifified `registry` project:
function setup(registry)
    ex = quote
        # TODO: replace Line 1 with Line 2 after MLJModelRegistry is registered at General:
        Pkg.develop(path=$ROOT) # Line 1
        # Pkg.add(MLJModelRegistryTools) # Line 2
    end
    future = GenericRegistry.run([], ex; environment=registry)
    fetch(future)
    GenericRegistry.close(future)
end

# remove MLJModelRegistryTools from the specifified `registry` project:
function cleanup(registry)
    ex = quote
        Pkg.rm("MLJModelRegistryTools")
    end
    future = GenericRegistry.run([], ex; environment=registry)
    fetch(future)
    GenericRegistry.close(future)
end

"""
    metadata(pkg; registry="", check_traits=true)

*Private method.*

Extract the metadata for a package. Returns a `Future` object that must be `fetch`ed to
get the metadata. See, [`MLJModelRegistryTools.update`](@ref), which calls this method, for
more details.

Assumes that MLJModelRegistryTools has been `develop`ed into `registry` if this is non-empty.

"""
function metadata(pkg; registry="", check_traits=true)
    if !isempty(registry)
        pkg in GenericRegistry.dependencies(registry) ||
            throw(err_missing_package(pkg, registry))
        setup=()
    else
        setup = quote
            # TODO: replace Line 1 with Line 2 after MLJModelRegistry is registered at
            # General:
            Pkg.develop(path=$ROOT) # Line 1
            # Pkg.add(MLJModelRegistryTools) # Line 2
        end
    end
    program = quote
        import MLJModelRegistryTools
        MLJModelRegistryTools.traits_given_constructor_name(
            $pkg,
            check_traits=$check_traits,
        )
    end
    return GenericRegistry.run(setup, pkg, program; environment=registry)
end


# # PUBLIC METHODS

"""
    MLJModelRegistryTools.gc()

Remove the metadata associated with any packages that are no longer in the the model
registry.

This is performed automatically after `update()`, but not after `update(pkg)`.

"""
gc() = GenericRegistry.gc(registry_path())


"""
    update(pkg; check_traits=true, advanced_options...)

Extract the values of model traits for models in the package `pkg`, including document
strings, and record this in the MLJ model registry (write it to
`/registry/Metadata.toml`).

Assumes `pkg` is already a dependency in the Julia environment defined at `/registry/` and
uses the version of `pkg` consistent with the current environment manifest, after
MLJModelRegistryTools.jl has been `develop`ed into that environment (it is removed again after
the update). See documentation for details on the registration process.

```julia-repl
julia> update("MLJDecisionTreeInterface")
```

# Return value

The metadata dictionary, keyed on models (more precisely, constructors, thereof).

# Advanced options

!!! warning

    Advanced options are intended primarily for diagnostic purposes.

- `manifest=true`: Set to `false` to ignore the registry environment manifest and instead
  add only the specified packages to a new temporary environment. Useful to temporarily
  force latest versions if these are being blocked by other packages.

- `debug=false`: Calling `update` opens a temporary Julia process to extract the trait
  metadata (see [`MLJModelRegistryTools.GenericRegistry.run`](@ref)). By default, this process
  is shut down before rethrowing any exceptions that occurs there. Setting `debug=true`
  will leave the process open, and also block the default suppression of the remote worker
  standard output.

"""
function update(pkg; debug=false, manifest=true, check_traits=true)
    registry = manifest ? registry_path() : ""
    @info INFO_BE_PATIENT1
    update(pkg, debug ? Loud() : Quiet(), registry, check_traits)
end
update(pkg, ::Loud, registry, check_traits) = _update(pkg, true, registry, check_traits)
update(pkg, ::Quiet, registry, check_traits) =
    @suppress _update(pkg, false, registry, check_traits)
function _update(pkg, debug, registry, check_traits)
    isempty(registry) || setup(registry)
    future = MLJModelRegistryTools.metadata(pkg; registry, check_traits)
    metadata = try
        fetch(future)
    catch excptn
        isempty(registry) || cleanup(registry)
        debug || GenericRegistry.close(future)
        rethrow(excptn)
    end
    isempty(registry) || cleanup(registry)
    debug || GenericRegistry.close(future)
    GenericRegistry.put(pkg, metadata, registry_path())
end

"""
    update(; check_traits=true, skip=String[], advanced_options...)

Update all packages in the Registry environment that are not specified in `skip`.

```julia-repl
julia> update(skip=["MLJBase", "MLJScikitlearnInterface"])
```

# Return value

A set of all names of all packages for which metadata was recorded.

# Advanced options

- `nworkers=otherBase.Sys.CPU_THREADS-1-nworkers())`: number of workers running package
  updates in parallel. Metadata is extracted in parallel, but written to file
  sequentially.

- `debug=false`: Set to `true` to leave temporary processes open; see the `update(pkg;
  ...)` document string above.

- `manifest=true`: See the `update(pkg; ...)` document string above.

"""
function update(
    ; nworkers=Base.Sys.CPU_THREADS - 1 - nworkers(),
    skip=String[],
    debug=false,
    manifest=true,
    check_traits=true,
    )
    registry = manifest ? registry_path() : ""
    allpkgs = GenericRegistry.dependencies(registry_path())
    if !isempty(registry)
        issubset(skip, allpkgs) || throw(err_invalid_packages(skip, registry))
        @suppress setup(registry)
    end
    pkgs = setdiff(allpkgs, skip) |> sort
    pkg_set = OrderedSet(pkgs)

    @info "Processing up to $nworkers packages at a time. "
    @info INFO_BE_PATIENT10
    while !isempty(pkg_set)
        print("\rPackages remaining: $(length(pkgs)) ")
        n = min(nworkers, length(pkg_set))
        batch = [pop!(pkg_set) for _ in 1:n]
        @suppress begin
            futures = [
                MLJModelRegistryTools.metadata(
                    pkg;
                    registry,
                    check_traits,
                ) for pkg in batch
                    ]
            try
                for (i, f) in enumerate(futures)
                    GenericRegistry.put(batch[i], fetch(f), registry_path())
                end
            catch excptn
                isempty(registry) || cleanup(registry)
                debug || GenericRegistry.close.(futures)
                rethrow(excptn)
            end
            debug || GenericRegistry.close.(futures)
        end
    end
    isempty(registry) || @suppress cleanup(registry)
    gc()
    println("\rPackages remaining: 0   ")
    return pkgs
end

"""
    MLJModelRegistryTools.get(pkg)

Inspect the model trait metadata recorded in the Model Registry for those models in
`pkg`. Returns a dictionary keyed on model constructor name. Data is in serialized form;
see [`MLJModelRegistryTools.encode_dic`](@ref).

"""
get(pkg) = GenericRegistry.get(pkg, registry_path())
