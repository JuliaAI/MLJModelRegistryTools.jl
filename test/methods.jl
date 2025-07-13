using Test
using MLJModelRegistryTools
import MLJModelRegistryTools.GenericRegistry as R
using Suppressor
using Random
using Distributed

N = nworkers()

@testset "clean!" begin
    dic = Dict(
        "Model1" => Dict(
            ":load_path" => "Pkg1.Mod1.Model1",
        ),
        "Model2" => Dict(
            ":load_path" => "Pkg2.Mod2.Model2",
        ),
    )
    MLJModelRegistryTools.clean!(dic, "Pkg1")
    @test keys(dic) == Set(["Model1"])
end

# build a dummmy registry:
registry = joinpath(tempdir(), randstring(20))
mkpath(registry)
project_string =
    """[deps]
       MLJBase = "a7f614a8-145f-11e9-1d2a-a57a1082229d"
       MLJDecisionTreeInterface = "c6f25543-311c-4c74-83dc-3ea6d1015661"
    """
project = joinpath(registry, "Project.toml")
manifest = joinpath(registry, "Manifest.toml")
open(project, "w") do file
    write(file, project_string)
end

@testset "metadata" begin
    @suppress begin
        MLJModelRegistryTools.setup(registry)
        future = MLJModelRegistryTools.metadata("MLJBase"; registry)
        dic = fetch(future)
        @test dic["Pipeline"][":human_name"] == "static pipeline"
        R.close(future)

        # This is just a smoke test of the `check_traits` option, to check it is
        # recognized:
        future = MLJModelRegistryTools.metadata(
            "MLJBase";
            registry,
            check_traits=false)
        fetch(future)
        R.close(future)

        # failure because "Example" is not in `registry`:
        @test_throws(
            MLJModelRegistryTools.err_missing_package("Example", registry),
            MLJModelRegistryTools.metadata("Example"; registry),
        )
        MLJModelRegistryTools.cleanup(registry)
    end
end

setpath(registry)

@testset "update" begin
    @test_throws(
        MLJModelRegistryTools.err_invalid_packages(["RoguePkg",], registry),
        MLJModelRegistryTools.update(skip=["RoguePkg",]),
    )
    traits_given_model = @test_logs(
        (:info, MLJModelRegistryTools.INFO_BE_PATIENT1),
        MLJModelRegistryTools.update("MLJBase"),
    )
    # check that MLJModelRegistryTools, temporarily added to `registry`, has been removed:
    @test !("MLJModelRegistryTools" in R.dependencies(registry))

    @test traits_given_model["Pipeline"][":name"] == "Pipeline"

    packages = @test_logs(
        (:info, ),
        (:info, MLJModelRegistryTools.INFO_BE_PATIENT10),
        MLJModelRegistryTools.update(),
    )
    @test "MLJDecisionTreeInterface" in packages
end

@testset "get" begin
    metadata = MLJModelRegistryTools.get("MLJDecisionTreeInterface")
    @test metadata["DecisionTreeClassifier"][":is_pure_julia"] == "`true`"
end

@testset "gc" begin
    # manually remove "MLJBase" from `registry`:
    @suppress begin
        future = R.run([], :(Pkg.rm("MLJBase")); environment=registry)
        fetch(future)
        R.close(future)
    end
    @assert !("MLJBase" in R.dependencies(registry))

    # check that gc removes the associated metadata:
    MLJModelRegistryTools.gc()
    @test isnothing(MLJModelRegistryTools.get("MLJBase"))
end

# check all temporary processes got shut down:
@test nworkers() == N

true
