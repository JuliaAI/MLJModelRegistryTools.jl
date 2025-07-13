# using ArgParse
"""
    GenericRegistry

Module providing basic tools to manage a *package registry*, by which is meant a package
environment, together with "package metata", in the form of a dictionary of TOML-parsable
values, keyed on the environment's package dependencies, which is stored in a TOML
file. (This file is called Metadata.toml and is located in the same folder as environment
Project.toml file.) Not to be confused with a package registry in the sense of the
standard library, `Pkg`.

# Methods

- `GenericRegistry.dependencies(environment)`: Get a list of the environment's
  dependencies (vector of package name strings).

- [`GenericRegistry.put`](@ref): Insert an item in the metadata dictionary

- [`GenericRegistry.get`](@ref): Inspect the metadata

- [`GenericRegistry.gc`](@ref): Remove key-value pairs fromn the metadata for package keys
  no longer dependencies in the environment. (In any case, `get` will return `nothing` for
  any `pkg` not currently a dependency.)

- [`GenericRegistry.run`](@ref): In a new Julia process, load a package or packages and
  execute a Julia expression there; results are returned as `Future` objects, to allow
  asynchronous `run` calls. Useful for generating metadata about a package.

- [`GenericRegistry.close(future)`](@ref): Shut down the process intitiated by the `run`
  call that returned `future` (after calling `fetch(future)` to get the result of
  evaluation).

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
Pkg.add("MLJModelRegistryTools")
using MLJModelRegistryTools.GenericRegistry
packages = GenericRegistry.dependencies(env)
# 2-element Vector{String}:
#  "Tables"
#  "Example"

future = GenericRegistry.run(["Tables",], :(names(Tables)))
value = fetch(future)
# 3-element Vector{Symbol}:
#  :Tables
#  :columntable
#  :rowtable

GenericRegistry.close(future)
GenericRegistry.put("Tables", string.(value), env)
read("/Users/anthony/MyEnv/Metadata.toml", String)
# "Tables = [\"Tables\", \"columntable\", \"rowtable\"]\n"

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
    GenericRegistry.run([setup,] packages, program; environment=nothing)

Assuming a package `environment` path is specified, do the following in a new Julia
process:

1. Activate `environment`.

2. Evaluate the `setup` expression, if specified.

3. Instantiate the environment.

4. `import` all packages specified in `packages`.

3. Evaluate the `program` expression.

The returned value is a `Future` object which must be `fetch`ed to get the final evaluated
expression. Shut the temporary process down by calling `GenericRegistry.close` on the
`Future`.

Step 3 might typically close by reversing any actions mutating the `environment`, but
remember only the last evaluated expression is passed to the `Future`.

If `environment` is unspecified, then a fresh temporary environment is activated, and the
packages listed in `packages` are manually added between Steps 2 and 3 above.

"""
function run(setup, pkgs, program; environment=nothing)
    pkgs isa Vector || (pkgs = [pkgs,])
    imports =  [:(import $(Symbol(pkg))) for pkg in pkgs]
    ex = quote
        using Pkg
    end
    if isnothing(environment)
        push!(
            ex.args,
            quote
                Pkg.activate(temp=true)
            end,
        )
    else
        push!(
            ex.args,
            quote
                Pkg.activate($environment)
            end,
        )
    end
    push!(ex.args, quote $setup end)
    if isnothing(environment)
        additions = [:(Pkg.add($pkg)) for pkg in pkgs]
        push!(
            ex.args,
            quote
                $(additions...)
            end,
        )
    end
    push!(
        ex.args,
        quote
            Pkg.instantiate()
            $(imports...)
            $program
        end,
    )
    return run_in_temporary_process(ex)
end
run(pkgs, program; kwargs...) = run(:(), pkgs, program; kwargs...)

"""
    GenericRegistry.close(future)

Shut down the Julia process whose output was encapsulated by the `Future` instance,
`future`.

"""
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
