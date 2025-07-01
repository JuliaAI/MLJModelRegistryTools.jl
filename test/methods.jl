using Test
using MLJModelRegistry
using Suppressor

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

future = MLJModelRegistry.metadata("BetaML")
fetch(future)
