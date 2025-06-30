const DOC_ADDING_PACKAGES = """

    Use Julia's package manager, `Pkg`, to add a new model-providing package to the
    environment at "/registry/". This is necessary before model medata can be generated
    and recorded.

    IMPORTANT: In any pull request to update the Model Registry you should note the final
    output of `Pkg.status(outdated=true)`.

    In detail, you will generally perform the following steps to add the new package:

    1. In your local clone of MLJModelRegistry.jl, `activate` the environment at  "/registry/".

    2. `update` the environment

    3. Note the output of `Pkg.status(outdated=true)`

    3. `add` the new package

    4. Repeat steps 2 and 3 above, and investigate any dependeny downgrades for which your addition may be responsible.

    If adding the new package results in downgrades to existing dependencies, your pull
    request to register the new models may be rejected.

    """

err_missing_package(pkg) = ArgumentError("""
    The package \"$pkg\" could not be found in the model registry. $DOC_ADDING_PACKAGES
    """
)

function metadata(pkg)
    pkg in GenericRegistry.dependencies(REGISTRY) || throw(err_missing_package(pkg))
    setup = quote
        # REMOVE THIS NEXT LINE AFTER TAGGING NEW MLJMODELINTERFACE
        Pkg.develop(path="/Users/anthony/MLJ/MLJModelInterface/")
        Pkg.develop(path=$ROOT)
    end
    program = quote
        import MLJModelRegistry
        MLJModelRegistry.traits_given_constructor_name()
    end
    return GenericRegistry.run(setup, pkg, program)
end
