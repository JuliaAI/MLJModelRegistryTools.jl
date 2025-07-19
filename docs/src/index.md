# MLJModelRegistryTools.jl

Tools to maintain the [MLJ](https://juliaml.ai) Model Registry.

## What's this repository for?

[MLJ](https://juliaml.ai) (Machine Learning in Julia) is a suite of Julia software
packages providing a machine learning toolbox. The *MLJ Model Registry* is a list of
packages providing MLJ interfaces to machine learning models, together with metadata
about those models, such as the type of data models can operate on, and their full
document strings. This package provides software tools for MLJ maintainers to manage the
Model Registry, for example to add the models provided by a new machine learning package
providing an MLJ interface for those models. It is not part of the standard MLJ
distribution.
  
The model registry itself is currently hosted by MLJModels.jl (part of the standard MLJ
distribution) and lives in [this
folder](https://github.com/JuliaAI/MLJModels.jl/tree/master/src/registry).
