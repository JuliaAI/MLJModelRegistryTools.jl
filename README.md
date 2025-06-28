# MLJModelRegistry.jl

Home of the MLJ Model Registry

[![Build Status](https://github.com/JuliaAI/MLJModelRegistry.jl/workflows/CI/badge.svg)](https://github.com/JuliaAI/MLJModelRegistry.jl/actions)
[![codecov](https://codecov.io/gh/JuliaAI/MLJModelRegistry.jl/graph/badge.svg?token=9IWT9KYINZ)](https://codecov.io/gh/JuliaAI/MLJModelRegistry.jl?branch=dev)
[![Docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://juliaai.github.io/MLJModelRegistry.jl/dev/)
[![Docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliaai.github.io/MLJModelRegistry.jl/stable/)

## What is this repository for?

[MLJ](https://juliaml.ai) (Machine Learning in Julia) is a suite of Julia software
packages providing a machine learning toolbox. The MLJModelRegistry.jl has two functions: 

- It hosts the *MLJ Model Registry*, a list of packages providing MLJ interfaces to
  machine learning algorithms, together with metadata about those models, such as the type
  of data models can operate on.
  
- It provides software tools for MLJ maintainers to manage the Model Registry, for example
  to add the models provided by a new machine learning package providing an MLJ model
  interface.
  
This repository does not provide any MLJ user code but does contain metadata downloaded as
a Julia `Artifact` by MLJ software. See the
[documentation](https://juliaai.github.io/MLJModelRegistry.jl/stable/) for details.


