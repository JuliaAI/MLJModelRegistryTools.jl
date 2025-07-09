# MLJModelRegistry.jl

Home of the MLJ Model Registry and tools to maintain it

# What's this repository for?

[MLJ](https://juliaml.ai) (Machine Learning in Julia) is a suite of Julia software
packages providing a machine learning toolbox. The MLJModelRegistry.jl repository has two
functions:

- It hosts the *MLJ Model Registry*, a list of packages providing MLJ interfaces to
  machine learning algorithms, together with metadata about those models, such as the type
  of data models can operate on, and their document strings.
  
- It provides software tools for MLJ maintainers to manage the Model Registry, for example
  to add the models provided by a new machine learning package providing an MLJ model
  interface for those models.
  
The model registry itself consists of files in [this
folder](https://github.com/JuliaAI/MLJModelRegisry.jl/master/registry/), ordinarily
accessed in one of two ways:

- By MLJ users, through the package
  [MLJModels.jl](https://github.com/JuliaAI/MLJModels.jl) which downloads the registry
  files as a Julia `Artifact`.

- By developers wishing to update the registry, but using software tools provided by the
  MLJModelRegistry.jl package, as described in this documentation.
  
As it is intended for MLJ developers only, none of the code provided in this repository is
part of the standard MLJ distribution.

