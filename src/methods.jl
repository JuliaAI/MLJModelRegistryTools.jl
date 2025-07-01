# # LOGGING AND ERRORS

err_missing_package(pkg) = ArgumentError("""

    Before calling `update` to record metadata for the \"$pkg\", the package
    must be added to the package environment at \"registry\". Refer to documentation for
    details. "

"""
)

err_invalid_packages(skip) = ArgumentError(
    "One or more packages from `skip=$skip` are not in the package environment at "*
    "\"registry\". "
)


# # HELPERS

function clean!(dic, pkg)
    for model in keys(dic)
        api_pkg = split(dic[model][":load_path"], '.') |> first
        api_pkg == pkg || (delete!(dic, model))
    end
    return dic
end

"""
    metadata(pkg; check_traits=true)

Extract the metadata for a package. Returns a `Future` object that must be `fetch`ed.

"""
function metadata(pkg; check_traits=true)
    pkg in GenericRegistry.dependencies(REGISTRY) || throw(err_missing_package(pkg))
    setup = quote
        # REMOVE THIS NEXT LINE AFTER TAGGING NEW MLJMODELINTERFACE
        Pkg.develop(path="/Users/anthony/MLJ/MLJModelInterface/")
        Pkg.develop(path=$ROOT)
    end
    program = quote
        import MLJModelRegistry
        dic = MLJModelRegistry.traits_given_constructor_name(
            $pkg,
            check_traits=$check_traits,
        )
    end
    return GenericRegistry.run(setup, pkg, program)
end


# # PUBLIC METHODS

"""
    MLJModelRegistry.gc()

Remove the metadata associated with any packages that are no longer in the the model
registry.

This is performed automatically after `update()`, but not after `update(pkg)`.

"""
gc() = GenericRegistry.gc(REGISTRY)


"""
    update(pkg; check_traits=true, advanced_options...)

Extract the values of model traits for models in the package `pkg`, including document
strings, and record it in the MLJ model registry (write it to
`/registry/Metadata.toml`).

Assumes `pkg` is already a dependency in the Julia enviroment defined at `/registry/`. See
[`MLJModelRegistry`](@ref) for details on the registration process.

```julia-repl
julia> update("MLJDecisionTreeInterface")
```

# Return value

A set of all names of all models (more precisely, constructors) for which metadata was
recorded.

# Advanced options

- `debug=false`: Calling `update` opens a temporary Julia process to extract the trait
  metadata (see [`MLJModelRegistry.GenericRegistry.run`](@ref)). By default, this process
  is shut down before rethrowing any exceptions that occurs there. Setting `debug=true`
  will leave the process open, and also block the default suppression of the remote worker
  standard output.

"""
update(pkg; debug=false, check_traits=true) =
    update(pkg, debug ? Loud() : Quiet(), check_traits)
update(pkg, ::Loud, check_traits) = _update(pkg, check_traits)
update(pkg, ::Quiet, check_traits) = @suppress _update(pkg, check_traits)
function _update(pkg, check_traits)
    future = MLJModelRegistry.metadata(pkg; check_traits)
    metadata = try
        fetch(future)
    catch excptn
        debug || GenericRegistry.close(future)
        rethrow(excptn)
    end
    GenericRegistry.close(future)
    GenericRegistry.put(pkg, metadata, REGISTRY)
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

- `debug=false`: By default, Julia processes used to extract metadata will be shut down
  before rethrowing any exceptions that occur there. Set this flag to `true` leave them
  open instead.

"""
function update(
    ; nworkers=Base.Sys.CPU_THREADS - 1 - nworkers(),
    check_traits=true,
    skip=String[],
    debug=false,
    )
    allpkgs = GenericRegistry.dependencies(REGISTRY)
    issubset(skip, allpkgs) || throw(err_invalid_packages(skip))
    pkgs = setdiff(allpkgs, skip)
    N = length(pkgs)
    pos = 1
    println("Processing $nworkers packages at a time. "*
        "Be patient, this may take ten "*
        "minutes or so...")
    while N ≥ 1
        print("\rPackages remaining: $N ")
        n = min(nworkers, N)
        batch = pkgs[pos:pos + n - 1]
        @suppress begin
            futures = [MLJModelRegistry.metadata(pkg; check_traits) for pkg in batch]
            try
                for (i, f) in enumerate(futures)
                    GenericRegistry.put(batch[i], fetch(f), REGISTRY)
                end
            catch excptn
                debug || GenericRegistry.close.(futures)
                rethrow(excptn)
            end
            GenericRegistry.close.(futures)
        end
        N -= n
    end
    gc()
    println("\rPackages remaining: 0   ")
    return pkgs
end

"""
    MLJModelRegistry.get(pkg)

Inspect the model trait metadata recorded in the Model Registry for those models in
`pkg`. Returns a dictionary keyed on model constructor name. Data is in serialized form
(see [`MLJModelRegistry.encode_dic`](@ref)).

"""
get(pkg) = GenericRegistry.get(pkg, REGISTRY)
