# using ArgParse
"""
    GenericRegistry

Module providing basic tools to manage a *package registry*, by which is meant a package
environment, together with "package metata", in the form of a dictionary of TOML-parsable
values, keyed on the environment's package dependencies, which is stored in a TOML file in
the same directory as the Project.toml file for the environment.  This file is called
Metadata.toml and lives in the environment file containing the environment Project.toml
file. Not to be confused with a package registry in the sense of the standard library,
`Pkg`.

# Methods

- `GenericRegistry.dependencies(environment)`: Get a list of the environment's
  dependencies (vector of package name strings).

- [`GenericRegistry.run`](@ref): In a new Julia process, load a package (or packages) from
  the package environment and execute a Julia expression there; results are returned as
  `Future` objects, to allow asynchronous `run` calls. Useful for generating metadata about
  a package.

- `GenericRegistry.close(future)`: Shut down the process intitiated by the `run`
  call that returned `future` (after calling `fetch(future)` to get the result of
  evaluation).

- [`GenericRegistry.put`](@ref): Insert an item in the metadata dictionary

- [`GenericRegistry.get`](@ref): Inspect the metadata

- [`GenericRegistry.gc`](@ref): Remove key-value pairs fromn the metadata for package keys
  no longer dependencies in the environment. (In any case, `get` will return `nothing` for
  any `pkg` not currently a dependency.)

# Example

```julia
using Pkg
env = "/Users/anthony/MyEnv"
Pkg.activate(env)
Pkg.status()
# Status `~/MyEnv/Project.toml`
#  [7876af07] Example v0.5.5
#  [bd369af6] Tables v1.12.1

Pkg.activate(temp=true)
Pkg.add("MLJModelRegistry")
using MLJModels.GenericRegistry
packages = GenericRegistry.dependencies(env)
# 2-element Vector{String}:
#  "Tables"
#  "Example"

future = GenericRegistry.run(:(names(Tables)), ["Tables",], env)
value = fetch(future)
# 3-element Vector{Symbol}:
#  :Tables
#  :columntable
#  :rowtable

GenericRegistry.close(future)
GenericRegistry.put("Tables", string.(value), env)
less("/Users/anthony/MyEnv/Metadata.toml")
# Tables = ["Tables", "columntable", "rowtable"]

GenericRegistry.get("Tables", env)
# 3-element Vector{String}:
#  "Tables"
#  "columntable"
#  "rowtable"
```
"""
module GenericRegistry

using Distributed
import Pkg
import Pkg.TOML as TOML


# # LOGGING

err_missing_packages(pkgs) = ArgumentError(
    "One or more of the following specified packages are not "*
        "dependencies in the specified environment. "
)

err_invalid_package(pkg) = ArgumentError(
    "The package \"$pkg\" is an invalid key, as it is "*
        "not a dependency in the specified environment. "
)

# # HELPERS

function run_in_temporary_process(ex)
    id = addprocs(1) |> only
    future = try
       remotecall(Main.eval, id, ex)
    catch ex
        rmprocs(id)
        rethrow(ex)
    end
    return future
end

function dependencies(env)
    project = joinpath(env, "Project.toml")
    # TODO: can `collect` be removed?
    keys(TOML.parsefile(project)["deps"]) |> collect
end

function corresponding_metadata(env)
    result = joinpath(env, "Metadata.toml")
    open(result, create=true) do file end
    return result
end


# # METHODS

"""
    GenericRegistry.run(ex, pkgs[, environment])

In a temporary Julia process, evaluate the expression `ex` after importing the specified
packages, `pkgs`, using an instantiated version of the specified package `environment`,
when specified. If `environment` is omitted, a fresh temporary environment is created, and
populated by only the specified packages, before instantiation.

The returned value is a `Future` object which must be `fetch`ed to get the actual
evaluated expression. Shut the temporary process down by calling `close` on the `Future`.

"""
function run(ex, pkgs, env)
    pkgs isa Vector || (pkgs = [pkgs,])
    issubset(pkgs, dependencies(env)) || throw(err_missing_packages(pkgs))
    imports =  [:(import $(Symbol(pkg))) for pkg in pkgs]
    program = quote
        using Pkg
        Pkg.activate($env)
        Pkg.instantiate()
        $(imports...)
        $ex
    end
    return run_in_temporary_process(program)
end

function run(ex, pkgs)
    pkgs isa Vector || (pkgs = [pkgs,])
    additions = [:(Pkg.add($pkg)) for pkg in pkgs]
    imports =  [:(import $(Symbol(pkg))) for pkg in pkgs]
    program = quote
        using Pkg
        Pkg.activate(temp=true)
        $(additions...)
        Pkg.instantiate()
        $(imports...)
        $ex
    end
    return run_in_temporary_process(program)
end

close(future) = rmprocs(future.where)

"""
    GenericRegistry.put(pkg, value, environment)

In the metata dictionary associated with specified package environment, assign `value` to
the key `pkg`.

"""
function put(pkg, value, env)
    pkg in dependencies(env) || throw(err_invalid_package(pkg))
    metadata = corresponding_metadata(env)
    d = TOML.parsefile(metadata)
    d[pkg] = value
    open(metadata, "w") do file
        TOML.print(file, d)
    end
    return value
end

"""
    GenericRegistry.get(pkg, environment)

Return the metadata associated with package, `pkg`, if it is a dependency of `environment`
and if `pkg` is a key in associated metadata dictionary. Otherwise, return `nothing`.

"""
function get(pkg, env)
    pkg in dependencies(env) || return nothing
    metadata = corresponding_metadata(env)
    d = TOML.parsefile(metadata)
    pkg in keys(d) || return nothing
    return d[pkg]
end

"""
    GenericRegistry.gc(environment)

Remove key-value pairs from the metadata dictionary associated with the specified
`environment` in all cases in which the key is not a package dependency. An optional
cleanup operation after removing a package from the environment's dependencies.

Does not change behaviour of metadata methods.

"""
function gc(env)
    metadata = corresponding_metadata(env)
    d = TOML.parsefile(metadata)
    for pkg in setdiff(keys(d), dependencies(env))
        delete!(d, pkg)
    end
    open(metadata, "w") do file
        TOML.print(file, d)
    end
    return nothing
end

end # module
