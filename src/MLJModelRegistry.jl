"""
    MLJModelRegistry

Module providing methods for managing the MLJ Model Registry. To modify the registry:

!!! important

    In any pull request to update the Model Registry you should note the final output of
    `Pkg.status(outdated=true)` when you have MLJModels/registry activated.

- Create a local clone of [MLJModels.jl](https://github.com/JuliaAI/MLJModels.jl), which
  hosts the registry. After making changes, you will be making a MLJModels.jl pull
  request.

- Use Julia's package manager to add or remove items from the list of registered packages
  in the environment "MLJModels/registry/". If adding a new item, see the protocol below.

- After adding MLJModelRegistry to some other Julia pkg environment you have activated
(e.g., a fresh temporary one) run `using MLJModelRegistry` to make the management tools
available.

- Point MLJModelRegistry to the location of the registry itself within your MLJModels.jl
  clone, using `setpath(path_to_registry)`, as in `setpath("MyPkgs/MLJModels/registry")`.

- To add or update the metadata associated with a package, run [`update(pkg)`](@ref).

- Assuming this is successful, update the metadata for *all* packages in the registry
  by running [`update()`](@ref).

- When satisfied, commit your changes to the clone and make a pull request to the
  MLJModelRegistry.jl repository that you cloned.

!!! note

    Removing a package from the registry environment does not remove its metadata (i.e.,
    from "/registry/Metatdata.toml"). However if you call `update()` to update all package
    metadata (or call [`MLJModelRegistry.ac()`](@ref)) the metadata for all orphaned
    packages is removed.

# Protocol for adding new packages to the registry environment

1. In your local clone of MLJModelRegistry.jl, `activate` the environment at  "/registry/".

2. `update` the environment

3. Note the output of `Pkg.status(outdated=true)`

3. `add` the new package

4. Repeat steps 2 and 3 above, and investigate any dependency downgrades for which your addition may be the cause.

If adding the new package results in downgrades to existing dependencies because your
package is not up to date with it's compatibility bounds, then your pull request to
register the new models may be rejected.

"""
module MLJModelRegistry

import MLJModelInterface
using OrderedCollections
using InteractiveUtils
using Suppressor
using Distributed

# for controlling logging:
struct Loud end
struct Quiet end

const ROOT = joinpath(@__DIR__, "..")

# initializes REGISTRY_PATH to "":
include("init.jl")

# setters and getters for REGISTRY_PATH:
include("setpath.jl")

# The MLJ Model Registry is a special case of a "generic model registry", as described in
# this file, defining the `GenericRegistry` module (which has methods, no types):
include("GenericRegistry.jl")

# method to apply smoke tests to trait values for a model type:
include("check_traits.jl")

# methods called on remote processes to help extract metadata for a package's models:
include("remote_methods.jl")

# top-level methods for registry management:
include("methods.jl")

export update, setpath

end # module
