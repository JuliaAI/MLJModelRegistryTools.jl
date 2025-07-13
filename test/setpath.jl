using Test
using MLJModelRegistryTools

@testset "setters and getters for registry path" begin
    @test_throws(
        MLJModelRegistryTools.ERR_REGISTRY_PATH,
        MLJModelRegistryTools.registry_path(),
    )
    setpath("google boogle")
    @test MLJModelRegistryTools.registry_path() == "google boogle"
    setpath("")
end
