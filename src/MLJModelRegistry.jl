"""
    MLJModelRegistry

Module providing methods for managing the MLJ Model Registry. To modify the registry:

- Create a local clone of the [MLJModelRegistry.jl
  repository](https://github.com/JuliaAI/MLJModelRegistry.jl)

- Use Julia's package manager to add or remove items from the list of registered packages
  in the environment "/registry/", located in the root directory of your clone. If adding
  a new item, see the protocol below.

- In a fresh temporary environment, run `Pkg.develop("path_to_clone")` and `using
  MLJModelRegistry`.

- To add or update the metadata associated with a package, run [`update(pkg)`](@ref).

- Alternatively, to update the metadata for *all* packages in the registry (optional but
  recommended), run [`update()`](@ref).

- When satisfied, commit your changes to the clone and make a pull request to the master
  MLJModelRegistry.jl repository.

!!! important

    Removing a package from the "/registry/" enviroment does not remove its metadata from
    the Model Registry (i.e., from "/registry/Metatdata.toml"). Unless you later call
    `update()` to update all package metadata (slow), you must call
    [`MLJModelRegistry.gc()`](@ref) to specifically remove metadata for all orphaned
    packages (fast).

# Protocol for adding new packages to the registry environment

!!! important

    In any pull request to update the Model Registry you should note the final
    output of `Pkg.status(outdated=true)`.

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

# Location of the MLJ model registry (a Julia pkg environment + metadata):
const ROOT = joinpath(@__DIR__, "..")
const REGISTRY = joinpath(ROOT, "registry")

# for controlling logging:
struct Loud end
struct Quiet end

# The MLJ Model Registry is a special case of a "generic model registry", as described in
# this file, defining the `GenericRegistry` module (which has methods, no types):
include("GenericRegistry.jl")
include("check_traits.jl")
include("remote_methods.jl")
include("methods.jl")

export update

end # module
