"""
    MLJModelRegistryTools

Module providing tools for managing the MLJ Model Registry. To modify the registry:

- Create a local clone of [MLJModels.jl](https://github.com/JuliaAI/MLJModels.jl), which
  hosts the registry. After making changes, you will be making a MLJModels.jl pull
  request.

- If needed, use Julia's package manager to add or remove items from the list of
  registered packages in the environment "/src/registry/", inside your MLJModels.jl
  clone. Follow the protocol below.

- In a new Julia session with MLJModelRegistryTools.jl installed, run `using
  MLJModelRegistryTools` to make the management tools available.

- Point the `MLJModelRegistryTools` module to the location of the registry itself within
  your MLJModels.jl clone, using `setpath(path_to_registry)`, as in
  `setpath("MyPkgs/MLJModels.jl/src/registry")`. To check this worked, try
  `MLJRegistryTools.get("MLJBase")`, to see the MLJBase.jl models.

- To add or update the metadata associated with a package, run [`update(pkg)`](@ref), as
  in `update("MLJTransforms"). Ensure that every model provided by the packge appears as a
  key in the returned value. Omissions may indicate a bad `load_path`.

- Assuming this is successful, update the metadata for *all* packages in the registry
  by running [`update()`](@ref).

- When satisfied, commit your changes to the clone and make a pull request to the
  MLJModels.jl repository that you cloned.

!!! important

    In any MLJModels.jl pull request to update the Model Registry you should note the
    final output of `Pkg.status(outdated=true)` when you have /src/registry activated.

# Protocol for adding new packages to the registry environment

1. In your local clone of MLJModels.jl, `activate` the environment at  "/src/registry/".

2. `update` the environment

3. Note the output of `Pkg.status(outdated=true)`

3. `add` the new package

4. Repeat steps 2 and 3 above, and investigate any dependency downgrades for which your addition may be the cause.

If adding the new package results in downgrades to existing dependencies, because your
package is not up to date with it's compatibility bounds, then your pull request to
register the new models may be rejected.

!!! note

    Removing a package from the registry environment does not remove its metadata. However
    if you call `update()` to update all package metadata (or call
    [`MLJModelRegistryTools.gc()`](@ref)) the metadata for all orphaned packages is
    removed.

"""
module MLJModelRegistryTools

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
