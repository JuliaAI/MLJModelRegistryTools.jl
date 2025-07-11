using Test
using MLJModelRegistry
import MLJModelRegistry.GenericRegistry as R
using Suppressor
using Random

@testset "clean!" begin
    dic = Dict(
        "Model1" => Dict(
            ":load_path" => "Pkg1.Mod1.Model1",
        ),
        "Model2" => Dict(
            ":load_path" => "Pkg2.Mod2.Model2",
        ),
    )
    MLJModelRegistry.clean!(dic, "Pkg1")
    @test keys(dic) == Set(["Model1"])
end

# build a dummmy registry:
registry = joinpath(tempdir(), randstring(20))
mkpath(registry)
const project_string =
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
        future = MLJModelRegistry.metadata("MLJBase"; environment=registry)
        dic = fetch(future)
        @test dic["Pipeline"][":human_name"] == "static pipeline"
        R.close(future)

        # This is just a smoke test of the `check_traits` option, to check it is
        # recognized:
        future = MLJModelRegistry.metadata(
            "MLJBase";
            environment=registry,
            check_traits=false)
        R.close(future)

        # failure because "Example" is not in `registry`:
        @test_throws(
            MLJModelRegistry.err_missing_package("Example", registry),
            MLJModelRegistry.metadata("Example"; environment=registry),
        )
    end
end

@testset "update, package checking" begin
    @test_throws(
        MLJModelRegistry.err_invalid_packages(["RoguePkg",], MLJModelRegistry.REGISTRY),
        MLJModelRegistry.update(skip=["RoguePkg",]),
    )
end

# These tests of `update` are suspended because they may mutate the contents of
# /registry/:

if false
@testset "update" begin
    traits_given_model = @test_logs(
        (:info, MLJModelRegistry.INFO_BE_PATIENT1),
        MLJModelRegistry.update("MLJBase"),
    )
    @test traits_given_model["Pipeline"][":name"] == "Pipeline"

    packages = @test_logs(
        (:info, ),
        (:info, MLJModelRegistry.INFO_BE_PATIENT10),
        MLJModelRegistry.update(),
    )
    @test "MLJBase" in packages
end
end

true
