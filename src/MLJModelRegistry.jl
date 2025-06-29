module MLJModelRegistry

import MLJModelInterface
using OrderedCollections
using InteractiveUtils

# Location of the MLJ model registry (a Julia pkg environment + metadata):
const ROOT = joinpath(@__DIR__, "..")
const REGISTRY = joinpath(ROOT, "registry")

# The MLJ Model Registry is a special case of a "generic model registry", as described in
# this file, defining the `GenericRegistry` module (which has methods, no types):
include("GenericRegistry.jl")
include("check_traits.jl")
include("remote_methods.jl")

end # module
